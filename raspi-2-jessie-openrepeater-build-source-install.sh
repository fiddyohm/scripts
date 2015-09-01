#!/bin/bash
(
####################################################################
#
#   Open Repeater Project
#
#    Copyright (C) <2015>  <Richard Neese> kb3vgw@gmail.com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.
#
#    If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>
#
###################################################################
# Auto Install Configuration options
# (set it, forget it, run it)
###################################################################

# ----- Start Edit Here ----- #
####################################################
# Repeater call sign
# Please change this to match the repeater call sign
####################################################
cs="Set_This"

################################################################
# Install Ajenti Optional Admin Portal (Optional) (Not Required)
#           (Currently broken on beaglebone installs)
################################################################
install_ajenti="n" #y/n

####################################################
# Install vsftpd for devel (Optional) (Not Required)
####################################################
install_vsftpd="y" #y/n

#####################
# set vsftp user name
#####################
vsftpd_user=""

########################
# set vsftp config path
########################
FTP_CONFIG_PATH="/etc/vsftpd.conf"

# ----- Stop Edit Here ------- #
########################################################
# Set mp3/wav file upload/post size limit for php/nginx
# ( Must Have the M on the end )
########################################################
upload_size="25M"

#######################
# Nginx default www dir
#######################
WWW_PATH="/var/www"

#################################
#set Web User Interface Dir Name
#################################
gui_name="openrepeater"

#####################
#Php ini config file
#####################
php_ini="/etc/php5/fpm/php.ini"
######################################################################
# check to see that the configuration portion of the script was edited
######################################################################
if [[ $cs == "Set-This" ]]; then
  echo
  echo "Looks like you need to configure the scirpt before running"
  echo "Please configure the script and try again"
  exit 0
fi

##################################################################
# check to confirm running as root. # First, we need to be root...
##################################################################
if [ "$(id -u)" -ne "0" ]; then
  sudo -p "$(basename "$0") must be run as root, please enter your sudo password : " "$0" "$@"
  exit 0
fi
echo
echo "Looks Like you are root.... continuing!"
echo

###############################################
#if lsb_release is not installed it installs it
###############################################
if [ ! -s /usr/bin/lsb_release ]; then
	apt-get update && apt-get -y install lsb-release
fi

#################
# Os/Distro Check
#################
lsb_release -c |grep -i jessie &> /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo " OK you are running Debian 8 : Jessie "
else
	echo " This script was written for Debian 8 Jessie "
	echo
	echo " Your OS appears to be: " lsb_release -a
	echo
	echo " Your OS is not currently supported by this script ... "
	echo
	echo " Exiting the install. "
	exit
fi

###########################################
# Run a OS and Platform compatabilty Check
###########################################
########
# ARMEL
########
case $(uname -m) in armv[4-5]l)
echo
echo " ArmEL is currenty UnSupported "
echo
exit
esac

########
# ARMHF
########
case $(uname -m) in armv[6-9]l)
echo
echo " ArmHF arm v6 v7 v8 v9 boards supported "
echo
esac

#############
# Intel/AMD
#############
case $(uname -m) in x86_64|i[4-6]86)
echo
echo " Intel / Amd boards currently UnSupported"
echo
exit
esac

#####################################
#Update base os with new repo in list
#####################################
apt-get update

###################
# Notes / Warnings
###################
echo
cat << DELIM
                   Not Ment For L.a.m.p Installs

                  L.A.M.P = Linux Apache Mysql PHP

                 THIS IS A ONE TIME INSTALL SCRIPT

             IT IS NOT INTENDED TO BE RUN MULTIPLE TIMES

         This Script Is Ment To Be Run On A Fresh Install Of

                         Debian 8 (Jessie)

     If It Fails For Any Reason Please Report To kb3vgw@gmail.com

   Please Include Any Screen Output You Can To Show Where It Fails

DELIM

###############################################################################################
#Testing for internet connection. Pulled from and modified
#http://www.linuxscrew.com/2009/04/02/tiny-bash-scripts-check-internet-connection-availability/
###############################################################################################
echo
echo "This Script Currently Requires a internet connection "
echo
wget -q --tries=10 --timeout=5 http://www.google.com -O /tmp/index.google &> /dev/null

if [ ! -s /tmp/index.google ];then
	echo "No Internet connection. Please check ethernet cable"
	/bin/rm /tmp/index.google
	exit 1
else
	echo "I Found the Internet ... continuing!!!!!"
	/bin/rm /tmp/index.google
fi
echo
printf ' Current ip is : '; ip -f inet addr show dev eth0 | sed -n 's/^ *inet *\([.0-9]*\).*/\1/p'
echo


backup default repo source.list
################################
echo " Making backup of sources.list prior to editing... "
cp /etc/apt/sources.list /etc/apt/sources.list.preOpenRepeater

#################################################################################################
# Setting apt_get to use the httpredirecter to get
# To have <APT> automatically select a mirror close to you, use the Geo-ip redirector in your
# sources.list "deb http://httpredir.debian.org/debian/ jessie main".
# See http://httpredir.debian.org/ for more information.  The redirector uses HTTP 302 redirects
# not dnS to serve content so is safe to use with Google dnS.
# See also <which httpredir.debian.org>.  This service is identical to http.debian.net.
#################################################################################################
echo "installing jessie release repo"
cat > "/etc/apt/sources.list" << DELIM
deb http://httpredir.debian.org/debian/ jessie main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-updates main contrib non-free

deb http://httpredir.debian.org/debian/ jessie-backports main contrib non-free
deb-src http://httpredir.debian.org/debian/ jessie-backports main contrib non-free

DELIM

#########################
#raspi2 repo
#########################
cat >> "/etc/apt/sources.list.d/raspi2.list" << DELIM
deb [trusted=yes] https://repositories.collabora.co.uk/debian/ jessie rpi2
DELIM

######################
#Update base os
######################
for i in update upgrade ;do apt-get -y "${i}" ; done

apt-get clean

##########################
#Installing Deps
##########################
apt-get install -y --force-yes sqlite3 libopus0 alsa-utils vorbis-tools sox libsox-fmt-mp3 librtlsdr0 \
		ntp libasound2 libspeex1 libgcrypt20 libpopt0 libgsm1 tcl8.6 alsa-base bzip2 flite screen time \
		uuid rsyslog vim install-info whiptail dialog logrotate cron usbutils git-core

########################
# Install Build Depends
#######################		
apt-get install -y g++ make libsigc++-2.0-dev groff libgsm1-dev libpopt-dev tcl8.6-dev libgcrypt20-dev \
	libspeex1-dev libasound2-dev doxygen

#########################
# get svxlink src
#########################
cd /usr/src
wget https://github.com/sm0svx/svxlink/archive/14.08.1.tar.gz
tar xzvf 14.08.01.tar.gz

#############################
#Build & Install svxllink
#############################
cd cd /usr/src/svxlink-14.08.1/src
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DBUILD_STATIC_LIBS -DUSE_OSS=no -DUSE_QT=no
make
make doc
make install
ldconfig

#######################################################
#Install svxlink en_US sounds
#Working on sounds pkgs for future release of svxlink
########################################################
cd /usr/share/svxlink/sounds
wget https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/14.08/svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
tar xjvf svxlink-sounds-en_US-heather-16k-13.12.tar.bz2
mv en_US-heather* en_US
cd /root

##############################
#Set a reboot if Kernel Panic
##############################
cat > /etc/sysctl.conf << DELIM
kernel.panic = 10
DELIM

####################################
# Set fs to run in a tempfs ramdrive
####################################
cat >> /etc/fstab << DELIM
tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0
tmpfs /var/tmp  tmpfs nodev,nosuid,mode=1777  0 0
DELIM

##########################################
#---Start of nginx / php5 install --------
##########################################
apt-get -y install ssl-cert openssl-blacklist nginx memcached php5-cli php5-common \
		php-apc php5-gd php-db php5-fpm php5-memcache php5-sqlite

apt-get clean
rm /var/cache/apt/archive/*

##################################################
# Changing file upload size from 2M to upload_size
##################################################
sed -i "$php_ini" -e "s#upload_max_filesize = 2M#upload_max_filesize = $upload_size#"

######################################################
# Changing post_max_size limit from 8M to upload_size
######################################################
sed -i "$php_ini" -e "s#post_max_size = 8M#post_max_size = $upload_size#"

#####################################################################################################
#Nginx config Copied from Debian nginx pkg (nginx on debian wheezy uses sockets by default not ports)
#####################################################################################################
cat > "/etc/nginx/sites-available/$gui_name"  << DELIM
server{
        listen 127.0.0.1:80;
        server_name 127.0.0.1;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        client_max_body_size 25M;
        client_body_buffer_size 128k;

        root /var/www/openrepeater;
        index index.php;

        location ~ \.php$ {
           include snippets/fastcgi-php.conf;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
              deny all;
        }
        location ~ .htpassword {
              deny all;
        }
        location ~^.+.(db)$ {
              deny all;
        }
} 
server{
        listen 443;
        listen [::]:443 default_server ipv6only=on;

        include snippets/snakeoil.conf;
        ssl  on;

        root /var/www/openrepeater;

        index index.php;

        server_name $gui_name;

        location / {
            try_files \$uri \$uri/ =404;
        }

        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            include fastcgi_params;
            fastcgi_pass unix:/var/run/php5-fpm.sock;
            fastcgi_param   SCRIPT_FILENAME /var/www/openrepeater/\$fastcgi_script_name;
        }

        # Disable viewing .htaccess & .htpassword & .db
        location ~ .htaccess {
                deny all;
        }
        location ~ .htpassword {
                deny all;
        }
        location ~^.+.(db)$ {
                deny all;
        }
}

DELIM

###############################################
# set nginx worker level limit for performance
###############################################
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cat > "/etc/nginx/nginx.conf"  << DELIM
user www-data;
worker_processes 4;
pid /run/nginx.pid;

events {
	worker_connections 768;
	# multi_accept on;
}

http {

	##
	# Basic Settings
	##

	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	keepalive_timeout 65;
	types_hash_max_size 2048;
	# server_tokens off;

	include /etc/nginx/mime.types;
	default_type application/octet-stream;

	##
	# SSL Settings
	##

	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
	ssl_prefer_server_ciphers on;

	##
	# Logging Settings
	##

	open_file_cache max=1000 inactive=20s;
	open_file_cache_valid 30s;
	open_file_cache_min_uses 2;
	open_file_cache_errors off;

	fastcgi_cache_path /var/cache/nginx levels=1:2 keys_zone=microcache:15M max_size=1000m inactive=60m;

	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;

	##
	# Gzip Settings
	##

	gzip on;
	gzip_static on;
	gzip_disable "msie6";

	include /etc/nginx/conf.d/*.conf;
	include /etc/nginx/sites-enabled/*;
}

DELIM

#################################
# Backup and replace www.conf
#################################
cp /etc/php5/fpm/pool.d/www.conf /etc/php5/fpm/pool.d/www.conf.orig

cat >  /etc/php5/fpm/pool.d/www.conf << DELIM
[www]

user = www-data
group = www-data

listen = /var/run/php5-fpm.sock

listen.owner = www-data
listen.group = www-data

pm = static

pm.max_children = 5

pm.start_servers = 2

pm.max_requests = 100

chdir = /
DELIM

#################################
# Backup and replace php5-fpm.conf
#################################
cp /etc/php5/fpm/php5-fpm.conf /etc/php5/fpm/php5-fpm.conf.orig

cat > /etc/php5/fpm/php5-fpm.conf << DELIM
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;include=/etc/php5/fpm/*.conf

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]

pid = /run/php5-fpm.pid

; Error log file
error_log = /var/log/php5-fpm.log

; syslog_facility is used to specify what type of program is logging the
; message. This lets syslogd specify that messages from different facilities
; will be handled differently.
; See syslog(3) for possible values (ex daemon equiv LOG_DAEMON)
; Default Value: daemon
;syslog.facility = daemon

syslog.ident = php-fpm

emergency_restart_threshold = 10

emergency_restart_interval = 1m

process_control_timeout = 10

process.max = 12

systemd_interval = 60

include=/etc/php5/fpm/pool.d/*.conf
DELIM

##############################################################
# linking fusionpbx nginx config from avaible to enabled sites
##############################################################
ln -s /etc/nginx/sites-available/"$gui_name" /etc/nginx/sites-enabled/"$gui_name"

######################
#disable default site
######################
rm -rf /etc/nginx/sites-enabled/default

# Make sure the path /var/www/ is owned by your web server user:
chown -R www-data:www-data /var/www

##############################
#Restarting Nginx and PHP FPM
##############################
for i in nginx php5-fpm ;do service "${i}" restart > /dev/null 2>&1 ; done

######################################################
# Pull openrepeater from github and then cp into place
######################################################
cd /usr/src
git clone https://github.com/OpenRepeater/webapp.git openrepeater-gui
cd openrepeater-gui

###############################
# create fhs layout directories
################################
mkdir -p /etc/openrepeater/svxlink
mkdir -p /usr/share/openrepeater/sounds
mkdir -p /usr/share/examples/openrepeater/install
mkdir -p /var/lib/openrepeater/db
mkdir -p /var/lib/openrepeater/recordings
mkdir -p /var/lib/openrepeater/macros
mkdir -p /var/www/openrepeater

##########################################
#copy openrepeater into proper fhs layout
##########################################
cp -rp install/sql /usr/share/examples/openrepeater/install
cp -rp install/svxlink /usr/share/examples/openrepeater/install
cp -rp install/courtesy_tones /usr/share/openrepeater/sounds
cp -rp theme functions dev includes *.php /var/www/openrepeater

#################################################
# Fetch and Install open repeater project web ui
# ################################################

apt-get install -y --force-yes openrepeater

find "$WWW_PATH" -type d -exec chmod 775 {} +
find "$WWW_PATH" -type f -exec chmod 664 {} +

chown -R www-data:www-data $WWW_PATH

cp /etc/default/svxlink /etc/default/svxlink.orig
cat > "/etc/default/svxlink" << DELIM
#############################################################################
#
# Configuration file for the SvxLink startup script /etc/init.d/svxlink
#
#############################################################################

# The log file to use
LOGFILE=/var/log/svxlink

# The PID file to use
PIDFILE=/var/run/svxlink.pid

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/svxlink.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

#uesd for openrepeater to get gpio pins
if [ -r /etc/openrepeater/svxlink/svxlink_gpio.conf ]; then
        . /etc/openrepeater/svxlink/svxlink_gpio.conf
fi

DELIM

mv /etc/default/remotetrx /etc/default/remotetrx.orig
cat > "/etc/default/remotetrx" << DELIM
#############################################################################
#
# Configuration file for the RemoteTrx startup script /etc/init.d/remotetrx
#
#############################################################################

# The log file to use
LOGFILE=/var/log/remotetrx

# The PID file to use
PIDFILE=/var/run/remotetrx.pid

# The user to run the SvxLink server as
RUNASUSER=svxlink

# Specify which configuration file to use
CFGFILE=/etc/openrepeater/svxlink/remotetrx.conf

# Environment variables to set up. Separate variables with a space.
ENV="ASYNC_AUDIO_NOTRIGGER=1"

DELIM

#making links...
ln -s /usr/share/openrepeater/sounds/courtesy_tones /var/www/openrepeater/courtesy_tones
ln -s /etc/openrepeater/svxlink/local-events.d/ /usr/share/svxlink/events.d/local
ln -s /var/log/svxlink /var/www/openrepeater/log

chown www-data:www-data /var/www/openrepeater/courtesy_tones

cp -rp /usr/share/examples/openrepeater/install/svxlink/* /etc/openrepeater/svxlink
cp -rp /usr/share/examples/openrepeater/install/sql/openrepeater.db /var/lib/openrepeater/db
cp -rp /usr/share/examples/openrepeater/install/sql/database.php /etc/openrepeater

chown -R www-data:www-data /var/lib/openrepeater /etc/openrepeater

#########################
#restart svxlink service
#########################
service svxlink restart

#####################################################################
# Configure Sudo / scripts for the gui to start/stop/restart svxlink
#####################################################################
cat > "/usr/local/bin/svxlink_restart" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running"
    echo "\$(date): Restarting svxlink service with updated configuration"
    sudo service svxlink try-restart
else
    echo "\$(date): \$SERVICE is not running"
    echo "\$(date): Starting svxlink up with first time new configuration"
    sudo service svxlink start
fi
DELIM

cat > "/usr/local/bin/svxlink_stop" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running, Stopping svxlink service"
    sudo svxlink stop
else
    echo "\$(date): \$SERVICE is not running"
fi
DELIM

cat > "/usr/local/bin/svxlink_start" << DELIM
#!/bin/bash
SERVICE=svxlink

ps -u \$SERVICE | grep -v grep | grep \$SERVICE > /dev/null
result=\$?
echo "exit code: \${result}"
if [ "\${result}" -eq "0" ] ; then
    echo "\$(date): \$SERVICE service running, all is fine"
else
    echo "\$(date): \$SERVICE is not running"
    echo "\$(date): Atempting to start svxlink"
    sudo service svxlink start
fi
DELIM

cat > "/usr/local/bin/repeater_reboot" << DELIM
#!/bin/bash
sudo -u www-data /sbin/reboot
DELIM

sudo chown root:www-data /usr/local/bin/svxlink_restart /usr/local/bin/svxlink_start /usr/local/bin/svxlink_stop /usr/local/bin/repeater_reboot
sudo chmod 550 /usr/local/bin/svxlink_restart /usr/local/bin/svxlink_start /usr/local/bin/svxlink_stop /usr/local/bin/repeater_reboot

cat >> /etc/sudoers << DELIM
#allow www-data to access amixer and service
www-data   ALL=(ALL) NOPASSWD: /usr/local/bin/svxlink_restart, NOPASSWD: /usr/local/bin/svxlink_start, NOPASSWD: /usr/local/bin/svxlink_stop, NOPASSWD: /usr/local/bin/repeater_reboot
DELIM

#############################
#Setting Host/Domain name
#############################
cat > /etc/hostname << DELIM
$cs-repeater
DELIM

#################
#Setup /etc/hosts
#################
cat > /etc/hosts << DELIM
127.0.0.1       localhost 
::1             localhost ip6-localhost ip6-loopback
fe00::0         ip6-localnet
ff00::0         ip6-mcastprefix
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters

127.0.0.1       $cs-repeater

DELIM

##########################
#ADD Ajenti repo 
##########################
if [[ $install_ajenti == "y" ]]; then
echo "Installing Ajenti Admin Portal repo"
cat > "/etc/apt/sources.list.d/ajenti.list" <<DELIM
deb http://repo.ajenti.org/debian main main debian
DELIM

######################
# add ajenti repo key
######################
wget http://repo.ajenti.org/debian/key -O- | apt-key add -

#################
# install ajenti
#################
apt-get update
apt-get install -y ajenti task python-memcache python-beautifulsoup
apt-get clean
fi

###############################################
# INSTALL FTP SERVER / ADD USER FOR DEVELOPMENT
###############################################
if [[ $install_vsftpd == "y" ]]; then
	apt-get install vsftpd

	edit_config $FTP_CONFIG_PATH anonymous_enable NO enabled
	edit_config $FTP_CONFIG_PATH local_enable YES enabled
	edit_config $FTP_CONFIG_PATH write_enable YES enabled
	edit_config $FTP_CONFIG_PATH local_umask 022 enabled

	cat "force_dot_files=YES" >> "$FTP_CONFIG_PATH"

	system vsftpd restart

	# ############################
	# ADD FTP USER & SET PASSWORD
	# ############################
	adduser $vsftpd_user
fi

########################################
#Install raspi-openrepeater-config menu
########################################
#apt-get install openrepeater-menu

##################################
# Enable New shellmenu for logins
# on enabled for root and only if 
# the file exist
##################################
cat > /root/.profile << DELIM

if [ -f /usr/local/bin/raspi-openrepeater-conf ]; then
        . /usr/local/bin/raspi-openrepeater-conf
fi

DELIM

echo " ########################################################################################## "
echo " #             The SVXLink Repeater / Echolink server Install is now complete             # "
echo " #                          and your system is ready for use..                            # "
echo " ########################################################################################## "
) | tee /root/install.log