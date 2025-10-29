# terraform-laravel-provisioning

```
IP URL : http://103.3.60.61/ 
```
## Credential

### SSH (Default port)

```
username : recruiter
password : Recruiter123!
```
### Akses db MySQL
Root Akses
```
username : root
password : xi4egz7U0rdIAhdfvLW4mRg3
```
Database

``` 
username : laravel-user
password : l12g3th8sys0DV3o9IBN
```
## Dokumentasi
Infrastructure-as-Code untuk melakukan provisioning Linode VM dan secara otomatis menginstal Laravel (versi terbaru), Nginx, PHP 8.3, Composer, MySQL 8, Node.js 22.x, dan Yarn menggunakan Terraform + cloud-init.

### Alasan kenapa saya memilih cloud-init
Saya memilih cloud-init karena keunggulan berikut:

* Berjalan saat awal booting, jadi tidak perlu menunggu ssh ready untuk bisa diakses (remote-exec)
* mudah untuk mereview automation script karena seperti kita menyiapkan command (perlu diingat ini non interactive jadi terkadang harus modifikasi).
* Setup mudah, tidak ribet

### Alur Kerja
* Terraform dijalankan, setelah berhasil di apply selanjutnya cloud-init yang Berjalan
* pada terraform, saya bagi menjadi 3 bagian, yaitu : output, variables, dan main.
* Output : berisikan return hasil dari terraform yang dijalankan, datanya dikirim ke cloud-init.yaml.tftpl untuk mengisi beberapa variable seperti password, nama aplikasi, nama db dkk supaya tidak perlu dimasukkan ulang
* variables : berisikan variable dan value sementara yang nantinya akan digunakan oleh file lain.
* main.tf : berisikan konfigurasi utama dari terraform dengan provider yang digunakan.

untuk provider, saya menggunakan :
* linode : 3.5.0
* hashicorp/random : 3.7.2 (random password generator)

kemudian untuk port, yang dibuka hanya port 22,80,443 dan 3306 dengan ketentuan inbound_policy kecuali port yang disebutkan semuanya di drop dan untuk outbound_policy menampilakn semuanya

pada main.tf, ada script dibawah ini
```
locals {
  cloud_init = base64encode(templatefile("${path.module}/cloud-init.yaml.tftpl", {
    authorized_ssh_key     = var.authorized_ssh_key
    root_password          = random_password.root_password.result
    mysql_root_password    = random_password.mysql_root_password.result
    mysql_app_password     = random_password.mysql_app_password.result
    mysql_db_name          = var.mysql_db_name
    mysql_app_user         = var.mysql_app_user
    app_name               = var.app_name
  }))
}
```
local.cloud_init menyimpan script cloud-init yang sudah dipersonalisasi dan siap dijalankan otomatis oleh Linode saat VM dibuat.

kemudian dibawah ini merupakan script untuk membuat instance. instance dengan spesifikasi "g6-standard-2" # 2 vCPU, 4GB, ubuntu 24 dan juga region singapore. di instance berikut juga sudah ditempelkan authorized ssh key (saya) sehingga bisa langsung login tanpa perlu password ke ssh
```
resource "linode_instance" "web" {
  label           = var.label
  image           = "linode/ubuntu24.04"
  region          = var.region
  type            = var.instance_type
  root_pass       = random_password.root_password.result
  authorized_keys = [var.authorized_ssh_key]
  tags            = var.tags

  metadata {
    user_data = local.cloud_init
  }
}

```

## Cloud-init script
pada cloud init terjadi beberapa hal otomatisasi yang berjalan ketika sistem pertama kali booting.
#### 1. Informasi Dasar sistem
```
hostname: ${app_name}-server
fqdn: ${app_name}.local
package_update: true
package_upgrade: true
timezone: Asia/Jakarta
```
* Menetapkan hostname dan FQDN server sesuai variabel ${app_name}.
* Mengatur zona waktu ke Asia/Jakarta.
* Menjalankan update dan upgrade paket sistem sebelum instalasi lain.

#### 2. Pembuatan akun pengguna
```
users:
  - name: deploy
    sudo: ALL=(ALL) NOPASSWD:ALL
    ...
  - name: recruiter
    ...
```
User deploy:

* Akun utama untuk deployment aplikasi.

* Dapat menjalankan perintah sudo tanpa password (NOPASSWD).

* Menggunakan SSH key untuk login (ssh_authorized_keys berisi ${authorized_ssh_key}).

User recruiter:

* Akun tambahan untuk akses manual (misalnya HR atau reviewer).

* Punya hak sudo, tetapi harus masukkan password.

* Password default: "Recruiter123!".

* ssh_pwauth: true mengizinkan login SSH menggunakan password (bukan hanya key).

#### 3. Konfigurasi Nginx
```
- path: /etc/nginx/sites-available/laravel.conf
  content: |
    server {
      listen 80;
      ...
```
konfigurasi menggunakan default dari laravel
#### 4. inisialisasi File MYSQL 
#### 5. runcmd, proses mengeksekusi script
##### a. instalasi php dan nginx.
disini saya menggunakan php v 8.3 dan nginx. kenapa 8.3 bukan 8.4, karena masihh panjang EOLnya dan juga tersedia php-fpm dan module lainnya sehingga lebih lengkap.
##### b. Menjalankan main service dan mengatur firewall
```
systemctl enable --now ssh
ufw allow OpenSSH
apt-get update && apt-get install ...
```
##### c. Setup Server MySQL 
```
debconf-set-selections ...
apt-get install -y mysql-server
systemctl enable --now mysql
mysql < /root/mysql_secure.sql
mysql < /root/mysql_app.sql
```
##### d. NodeJS dan Yarn.
```
sudo -i -u deploy bash -lc '
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash;
  nvm install 22;
  corepack enable;
  corepack prepare yarn@stable --activate;
'
```

##### e. composer dan laravel ci 
```
curl -sS https://getcomposer.org/installer ...
php /tmp/composer-setup.php ...
sudo -u deploy bash -lc "composer global require laravel/installer"
```
##### f. setup laravel project dan konfigurasi ENV
```
sudo -u deploy bash -lc "cd /var/www/html && laravel new ${app_name}"
sed -i 's/^DB_CONNECTION=.*/DB_CONNECTION=mysql/' ...

```

##### g. Menjalankan setup laravel dan build Frontend asset
```
sudo -i -u deploy bash -lc "cd /var/www/html/${app_name} && yarn install && yarn build"

sudo -i -u deploy bash -lc "cd /var/www/html/${app_name} && yarn install && yarn build"

```

##### h. firewall dan auto restart
```
ufw allow 'Nginx Full'
systemctl enable --now php8.3-fpm nginx mysql ssh
```

## Kesulitan
saya mengalami kendala pada saat tahap deploy nodejs. pada Cloud Init selalu gagal, variable tidak ditemukan padahaal sudah dideclare. karena cukup lama dan hanya itu akhirnya saya install secara manual. dan hasilnya dapat dilihat dari URL diatas.


Terima kasih :)
