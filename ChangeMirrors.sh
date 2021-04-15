#!/bin/env bash
#Author:SuperManito

## 定义配置文件变量：
DebianConfig=/etc/apt/sources.list
DebianConfigBackup=/etc/apt/sources.list.bak
RedHatDirectory=/etc/yum.repos.d
RedHatDirectoryBackup=/etc/yum.repos.d.bak

## 判定系统是基于 Debian 还是 RedHat
ls /etc | grep redhat-release -qw
if [ $? -eq 0 ]; then
  SYSTEM="RedHat"
else
  SYSTEM="Debian"
fi

## 系统判定变量（名称、版本、版本号、使用架构）
if [ $SYSTEM = "Debian" ]; then
  SYSTEM_NAME=$(lsb_release -is)
  SYSTEM_VERSION=$(lsb_release -cs)
  SYSTEM_VERSION_NUMBER=$(lsb_release -rs)
elif [ $SYSTEM = "RedHat" ]; then
  SYSTEM_NAME=$(cat /etc/redhat-release | cut -c1-6)
  if [ $SYSTEM_NAME = "CentOS" ]; then
    SYSTEM_VERSION_NUMBER=$(cat /etc/redhat-release | cut -c22-24)
    CENTOS_VERSION=$(cat /etc/redhat-release | cut -c22)
  elif [ $SYSTEM_NAME = "Fedora" ]; then
    SYSTEM_VERSION_NUMBER=$(cat /etc/redhat-release | cut -c16-18)
  fi
fi

Architecture=$(arch)
if [ $Architecture = "x86_64" ]; then
  SYSTEM_ARCH=x86_64
  UBUNTU_ARCH=ubuntu
elif [ $Architecture = "aarch64" ]; then
  SYSTEM_ARCH=ARM64
  UBUNTU_ARCH=ubuntu_port
else
  SYSTEM_ARCH=${Architecture}
  UBUNTU_ARCH=ubuntu_port
fi

## 更换国内源：
function ChangeMirrors() {
  echo -e ''
  echo -e '+---------------------------------------------------+'
  echo -e '|                                                   |'
  echo -e '|   =============================================   |'
  echo -e '|                                                   |'
  echo -e '|         欢迎使用 Linux 一键更换国内源脚本         |'
  echo -e '|                                                   |'
  echo -e '|   =============================================   |'
  echo -e '|                                                   |'
  echo -e '+---------------------------------------------------+'
  echo -e ''
  echo -e '#####################################################'
  echo -e ''
  echo -e '            提供以下国内更新源可供选择：'
  echo -e ''
  echo -e '#####################################################'
  echo -e ''
  echo -e ' *  1)    阿里云'
  echo -e ' *  2)    腾讯云'
  echo -e ' *  3)    华为云'
  echo -e ' *  4)    网易'
  echo -e ' *  4)    搜狐'
  echo -e ' *  6)    清华大学'
  echo -e ' *  7)    浙江大学'
  echo -e ' *  8)    重庆大学'
  echo -e ' *  9)    兰州大学'
  echo -e ' *  10)   上海交通大学'
  echo -e ' *  11)   中国科学技术大学'
  echo -e ''
  echo -e '#####################################################'
  echo -e ''
  echo -e "         操作系统  $SYSTEM_NAME $SYSTEM_VERSION_NUMBER $SYSTEM_ARCH"
  echo -e "         系统时间  $(date "+%Y-%m-%d %H:%M:%S")"
  echo -e ''
  echo -e '#####################################################'
  echo -e ''
  CHOICE_A=$(echo -e '\033[32m└ 请输入您想使用的国内更新源 [ 1~11 ]：\033[0m')
  read -p "$CHOICE_A" INPUT
  case $INPUT in
  1)
    SOURCE="mirrors.aliyun.com"
    ;;
  2)
    SOURCE="mirrors.cloud.tencent.com"
    ;;
  3)
    SOURCE="mirrors.huaweicloud.com"
    ;;
  4)
    SOURCE="mirrors.163.com"
    ;;
  5)
    SOURCE="mirrors.sohu.com"
    ;;
  6)
    SOURCE="mirrors.tuna.tsinghua.edu.cn"
    ;;
  7)
    SOURCE="mirrors.zju.edu.cn"
    ;;
  8)
    SOURCE="mirrors.cqu.edu.cn"
    ;;
  9)
    SOURCE="mirror.lzu.edu.cn"
    ;;
  10)
    SOURCE="ftp.sjtu.edu.cn"
    ;;
  11)
    SOURCE="mirrors.ustc.edu.cn"
    ;;
  *)
    SOURCE="mirrors.aliyun.com"
    echo -e '\n\033[33m---------- 输入错误，更新源将默认使用阿里源 ---------- \033[0m'
    sleep 2s
    ;;
  esac

  ## 备份原有源文件
  MirrorsBackup

  if [ $SYSTEM = "Debian" ]; then
    DebianMirrors
  elif [ $SYSTEM = "RedHat" ]; then
    RedHatOfficialMirrorsCreate
    RedHatMirrors
  fi

  ## 升级软件包
  UpgradeSoftware
}

## 备份原有源文件
function MirrorsBackup() {
  if [ $SYSTEM = "Debian" ]; then
    ls /etc/apt | grep sources.list.bak -qw
    if [ $? -eq 0 ]; then
      echo -e "\n\033[32m└ 检测到已备份的 source.list 源文件，跳过备份操作...... \033[0m\n"
    else
      cp -rf ${DebianConfig} ${DebianConfigBackup} >/dev/null 2>&1
      echo -e "\n\033[32m└ 已备份原有 source.list 源文件至 ${DebianConfigBackup} ...... \033[0m\n"
    fi
    sleep 2s
  elif [ $SYSTEM = "RedHat" ]; then
    ls /etc | grep yum.repos.d.bak -qw
    if [ $? -eq 0 ]; then
      echo -e "\n\033[32m└ 检测到已备份的 repo 源文件，跳过备份操作...... \033[0m\n"
    else
      mkdir -p ${RedHatDirectoryBackup}
      cp -rf ${RedHatDirectory}/* ${RedHatDirectoryBackup} >/dev/null 2>&1
      echo -e "\n\033[32m└ 已备份原有 repo 源文件至 ${RedHatDirectoryBackup} ...... \033[0m\n"
    fi
    sleep 2s
  fi
}

## 更新软件包
function UpgradeSoftware() {
  CHOICE_B=$(echo -e '\n\033[32m└ 是否更新软件包 [ Y/N ]：\033[0m')
  read -p "$CHOICE_B" INPUT
  case $INPUT in
  [Yy]*)
    echo -e ''
    if [ $SYSTEM = "Debian" ]; then
      apt-get dist-upgrade -y
    elif [ $SYSTEM = "RedHat" ]; then
      yum update -y
    fi
    ;;
  [Nn]*) ;;
  *)
    echo -e '\n\033[33m---------- 输入错误，默认不更新软件包 ---------- \033[0m\n'
    ;;
  esac
}

## 基于 Debian 系 Linux 发行版的 source 源
function DebianMirrors() {
  sed -i '1,$d' ${DebianConfig}
  if [ $SYSTEM_NAME = "Ubuntu" ]; then
    echo "deb https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION main restricted universe multiverse" >>${DebianConfig}
    echo "deb-src https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION main restricted universe multiverse" >>${DebianConfig}
    echo "deb https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-security main restricted universe multiverse" >>${DebianConfig}
    echo "deb-src https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-security main restricted universe multiverse" >>${DebianConfig}
    echo "deb https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-updates main restricted universe multiverse" >>${DebianConfig}
    echo "deb-src https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-updates main restricted universe multiverse" >>${DebianConfig}
    echo "deb https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-proposed main restricted universe multiverse" >>${DebianConfig}
    echo "deb-src https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-proposed main restricted universe multiverse" >>${DebianConfig}
    echo "deb https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-backports main restricted universe multiverse" >>${DebianConfig}
    echo "deb-src https://$SOURCE/$UBUNTU_ARCH $SYSTEM_VERSION-backports main restricted universe multiverse" >>${DebianConfig}
  elif [ $SYSTEM_NAME = "Debian" ]; then
    echo "deb https://$SOURCE/debian $SYSTEM_VERSION main contrib non-free" >>${DebianConfig}
    echo "deb-src https://$SOURCE/debian $SYSTEM_VERSION main contrib non-free" >>${DebianConfig}
    echo "deb https://$SOURCE/debian $SYSTEM_VERSION-updates main contrib non-free" >>${DebianConfig}
    echo "deb-src https://$SOURCE/debian $SYSTEM_VERSION-updates main contrib non-free" >>${DebianConfig}
    echo "deb https://$SOURCE/debian $SYSTEM_VERSION-backports main contrib non-free" >>${DebianConfig}
    echo "deb-src https://$SOURCE/debian $SYSTEM_VERSION-backports main contrib non-free" >>${DebianConfig}
    echo "deb https://$SOURCE/debian-security $SYSTEM_VERSION/updates main contrib non-free" >>${DebianConfig}
    echo "deb-src https://$SOURCE/debian-security $SYSTEM_VERSION/updates main contrib non-free" >>${DebianConfig}
  elif [ $SYSTEM_NAME = "Kali" ]; then
    echo "deb https://$SOURCE/kali $SYSTEM_VERSION main non-free contrib" >>${DebianConfig}
    echo "deb-src https://$SOURCE/kali $SYSTEM_VERSION main non-free contrib" >>${DebianConfig}
  fi
  apt-get update
}

## 基于 RedHat 系 Linux 发行版的 repo 源
function RedHatMirrors() {
  if [ $SYSTEM_NAME = "CentOS" ]; then
    sed -i 's|^mirrorlist=|#mirrorlist=|g' ${RedHatDirectory}/CentOS-*.repo
    sed -i 's|^#baseurl=http://mirror.centos.org/$contentdir|baseurl=https://mirror.centos.org/centos|g' ${RedHatDirectory}/CentOS-*.repo
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://mirror.centos.org|g' ${RedHatDirectory}/CentOS-*.repo
    sed -i "s|mirror.centos.org|$SOURCE|g" ${RedHatDirectory}/CentOS-*.repo
  elif [ $SYSTEM_NAME = "Fedora" ]; then
    sed -i 's|^metalink=|#metalink=|g' \
      ${RedHatDirectory}/fedora.repo \
      ${RedHatDirectory}/fedora-updates.repo \
      ${RedHatDirectory}/fedora-modular.repo \
      ${RedHatDirectory}/fedora-updates-modular.repo \
      ${RedHatDirectory}/fedora-updates-testing.repo \
      ${RedHatDirectory}/fedora-updates-testing-modular.repo
    sed -i 's|^#baseurl=|baseurl=|g' ${RedHatDirectory}/*
    sed -i "s|http://download.example/pub/fedora/linux|https://$SOURCE/fedora|g" \
      ${RedHatDirectory}/fedora.repo \
      ${RedHatDirectory}/fedora-updates.repo \
      ${RedHatDirectory}/fedora-modular.repo \
      ${RedHatDirectory}/fedora-updates-modular.repo \
      ${RedHatDirectory}/fedora-updates-testing.repo \
      ${RedHatDirectory}/fedora-updates-testing-modular.repo
  fi
  yum makecache
}

## 生成基于 RedHat 发行版和及其衍生发行版的 repo 官方 repo 源文件
function RedHatOfficialMirrorsCreate() {
  if [ $SYSTEM_NAME = "CentOS" ]; then
    if [ $CENTOS_VERSION -eq "8" ]; then
      cd ${RedHatDirectory}
      rm -rf *AppStream.repo *BaseOS.repo *ContinuousRelease.repo *Debuginfo.repo *Devel.repo *Extras.repo *HighAvailability.repo *Media.repo *Plus.repo *PowerTools.repo *Sources.repo
      touch ${RedHatDirectory}/CentOS-Linux-AppStream.repo
      touch ${RedHatDirectory}/CentOS-Linux-BaseOS.repo
      touch ${RedHatDirectory}/CentOS-Linux-ContinuousRelease.repo
      touch ${RedHatDirectory}/CentOS-Linux-Debuginfo.repo
      touch ${RedHatDirectory}/CentOS-Linux-Devel.repo
      touch ${RedHatDirectory}/CentOS-Linux-Extras.repo
      touch ${RedHatDirectory}/CentOS-Linux-FastTrack.repo
      touch ${RedHatDirectory}/CentOS-Linux-HighAvailability.repo
      touch ${RedHatDirectory}/CentOS-Linux-Media.repo
      touch ${RedHatDirectory}/CentOS-Linux-Plus.repo
      touch ${RedHatDirectory}/CentOS-Linux-PowerTools.repo
      touch ${RedHatDirectory}/CentOS-Linux-Sources.repo
      cat >${RedHatDirectory}/CentOS-Linux-AppStream.repo <<\EOF
# CentOS-Linux-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=CentOS Linux $releasever - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-BaseOS.repo <<\EOF
# CentOS-Linux-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=CentOS Linux $releasever - BaseOS
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-ContinuousRelease.repo <<\EOF
# CentOS-Linux-ContinuousRelease.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.
#
# The Continuous Release (CR) repository contains packages for the next minor
# release of CentOS Linux.  This repository only has content in the time period
# between an upstream release and the official CentOS Linux release.  These
# packages have not been fully tested yet and should be considered beta
# quality.  They are made available for people willing to test and provide
# feedback for the next release.

[cr]
name=CentOS Linux $releasever - ContinuousRelease
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=cr&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/cr/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Debuginfo.repo <<\EOF
# CentOS-Linux-Debuginfo.repo
#
# All debug packages are merged into a single repo, split by basearch, and are
# not signed.

[debuginfo]
name=CentOS Linux $releasever - Debuginfo
baseurl=http://debuginfo.centos.org/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Devel.repo <<\EOF
# CentOS-Linux-Devel.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[devel]
name=CentOS Linux $releasever - Devel WARNING! FOR BUILDROOT USE ONLY!
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=Devel&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/Devel/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Extras.repo <<\EOF
# CentOS-Linux-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=CentOS Linux $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-FastTrack.repo <<\EOF
# CentOS-Linux-FastTrack.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[fasttrack]
name=CentOS Linux $releasever - FastTrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/fasttrack/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-HighAvailability.repo <<\EOF
# CentOS-Linux-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=CentOS Linux $releasever - HighAvailability
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=HighAvailability&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Media.repo <<\EOF
# CentOS-Linux-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=CentOS Linux $releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Linux $releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Plus.repo <<\EOF
# CentOS-Linux-Plus.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[plus]
name=CentOS Linux $releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/centosplus/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-PowerTools.repo <<\EOF
# CentOS-Linux-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=CentOS Linux $releasever - PowerTools
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=PowerTools&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
      cat >${RedHatDirectory}/CentOS-Linux-Sources.repo <<\EOF
# CentOS-Linux-Sources.repo


[baseos-source]
name=CentOS Linux $releasever - BaseOS - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Linux $releasever - AppStream - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Linux $releasever - Extras - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[plus-source]
name=CentOS Linux $releasever - Plus - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    elif [ $CENTOS_VERSION -eq "7" ]; then
      cd ${RedHatDirectory}
      rm -rf *Base.repo *BaseOS.repo *CR.repo *Debuginfo.repo *fasttrack.repo *Media.repo *Sources.repo *Vault.repo
      touch ${RedHatDirectory}/CentOS-Base.repo
      touch ${RedHatDirectory}/CentOS-CR.repo
      touch ${RedHatDirectory}/CentOS-Debuginfo.repo
      touch ${RedHatDirectory}/CentOS-fasttrack.repo
      touch ${RedHatDirectory}/CentOS-Media.repo
      touch ${RedHatDirectory}/CentOS-Sources.repo
      touch ${RedHatDirectory}/CentOS-Vault.repo
      cat >${RedHatDirectory}/CentOS-BaseOS.repo <<\EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
      cat >${RedHatDirectory}/CentOS-CR.repo <<\EOF
# CentOS-CR.repo
#
# The Continuous Release ( CR )  repository contains rpms that are due in the next
# release for a specific CentOS Version ( eg. next release in CentOS-7 ); these rpms
# are far less tested, with no integration checking or update path testing having
# taken place. They are still built from the upstream sources, but might not map 
# to an exact upstream distro release.
#
# These packages are made available soon after they are built, for people willing 
# to test their environments, provide feedback on content for the next release, and
# for people looking for early-access to next release content.
#
# The CR repo is shipped in a disabled state by default; its important that users 
# understand the implications of turning this on. 
#
# NOTE: We do not use a mirrorlist for the CR repos, to ensure content is available
#       to everyone as soon as possible, and not need to wait for the external
#       mirror network to seed first. However, many local mirrors will carry CR repos
#       and if desired you can use one of these local mirrors by editing the baseurl
#       line in the repo config below.
#

[cr]
name=CentOS-$releasever - cr
baseurl=http://mirror.centos.org/centos/$releasever/cr/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0
EOF
      cat >${RedHatDirectory}/CentOS-Debuginfo.repo <<\EOF
# CentOS-Debug.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#

# All debug packages from all the various CentOS-7 releases
# are merged into a single repo, split by BaseArch
#
# Note: packages in the debuginfo repo are currently not signed
#

[base-debuginfo]
name=CentOS-7 - Debuginfo
baseurl=http://debuginfo.centos.org/7/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-7
enabled=0
#
EOF
      cat >${RedHatDirectory}/CentOS-fasttrack.repo <<\EOF
[fasttrack]
name=CentOS-7 - fasttrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/fasttrack/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
      cat >${RedHatDirectory}/CentOS-Media.repo <<\EOF
# CentOS-Media.repo
#
#  This repo can be used with mounted DVD media, verify the mount point for
#  CentOS-7.  You can use this repo and yum to install items directly off the
#  DVD ISO that we release.
#
# To use this repo, put in your DVD and use it with the other repos too:
#  yum --enablerepo=c7-media [command]
#  
# or for ONLY the media repo, do this:
#
#  yum --disablerepo=\* --enablerepo=c7-media [command]

[c7-media]
name=CentOS-$releasever - Media
baseurl=file:///media/CentOS/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
      cat >${RedHatDirectory}/CentOS-Sources.repo <<\EOF
# CentOS-Sources.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base-source]
name=CentOS-$releasever - Base Sources
baseurl=http://vault.centos.org/centos/$releasever/os/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates-source]
name=CentOS-$releasever - Updates Sources
baseurl=http://vault.centos.org/centos/$releasever/updates/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras-source]
name=CentOS-$releasever - Extras Sources
baseurl=http://vault.centos.org/centos/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus-source]
name=CentOS-$releasever - Plus Sources
baseurl=http://vault.centos.org/centos/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
    fi
  elif [ $SYSTEM_NAME = "Fedora" ]; then
    cd ${RedHatDirectory}
    rm -rf *cisco-openh264.repo fedora.repo *updates.repo *modular.repo *updates-modular.repo *updates-testing-modular.repo
    touch ${RedHatDirectory}/fedora-cisco-openh264.repo
    touch ${RedHatDirectory}/fedora.repo
    touch ${RedHatDirectory}/fedora-updates.repo
    touch ${RedHatDirectory}/fedora-modular.repo
    touch ${RedHatDirectory}/fedora-updates-modular.repo
    touch ${RedHatDirectory}/fedora-updates-testing.repo
    touch ${RedHatDirectory}/fedora-updates-testing-modular.repo
    cat >${RedHatDirectory}/fedora-cisco-openh264.repo <<\EOF
[fedora-cisco-openh264]
name=Fedora $releasever openh264 (From Cisco) - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch
type=rpm
enabled=1
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True

[fedora-cisco-openh264-debuginfo]
name=Fedora $releasever openh264 (From Cisco) - $basearch - Debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-debug-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True
EOF
    cat >${RedHatDirectory}/fedora.repo <<\EOF
[fedora]
name=Fedora $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-debuginfo]
name=Fedora $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-source]
name=Fedora $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >${RedHatDirectory}/fedora-updates.repo <<\EOF
[updates]
name=Fedora $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-debuginfo]
name=Fedora $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-source]
name=Fedora $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >${RedHatDirectory}/fedora-modular.repo <<\EOF
[fedora-modular]
name=Fedora Modular $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-$releasever&arch=$basearch
enabled=1
countme=1
#metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-source]
name=Fedora Modular $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >${RedHatDirectory}/fedora-updates-modular.repo <<\EOF
[updates-modular]
name=Fedora Modular $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-source]
name=Fedora Modular $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >${RedHatDirectory}/fedora-updates-testing.repo <<\EOF
[updates-testing]
name=Fedora $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-debuginfo]
name=Fedora $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-source]
name=Fedora $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >${RedHatDirectory}/fedora-updates-testing-modular.repo <<\EOF
[updates-testing-modular]
name=Fedora Modular $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-source]
name=Fedora Modular $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
  fi
}

ChangeMirrors