#!/bin/bash

. $TESTSLIB/quiet.sh

debian_name_package() {
    case "$1" in
        xdelta3)
            ;&
        curl)
            ;&
        jq)
            ;&
        printer-driver-cups-pdf)
            ;&
        python3-yaml)
            echo $1
            ;;
    esac
}

ubuntu_14_04_name_package() {
    case "$1" in
        printer-driver-cups-pdf)
            echo "cups-pdf"
            ;;
        *)
            debian_name_package $1
            ;;
    esac
}

fedora_name_package() {
    case "$1" in
        xdelta3)
            ;&
        jq)
            ;&
        curl)
            echo $1
            ;;
        python3-yaml)
            echo "python3-yamlordereddictloader"
            ;;
        openvswitch-switch)
            echo "openvswitch"
            ;;
        printer-driver-cups-pdf)
            echo "cups-pdf"
            ;;
        *)
            echo $1
            ;;
    esac
}

distro_name_package() {
    case "$SPREAD_SYSTEM" in
        ubuntu-14.04-*)
            ubuntu_14_04_name_package $1
            ;;
        ubuntu-*)
            ;&
        debian-*)
            debian_name_package $1
            ;;
        fedora-*)
            fedora_name_package $1
            ;;
        *)
            echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
            exit 1
            ;;
    esac
}

distro_install_local_package() {
    case "$SPREAD_SYSTEM" in
        ubuntu-*)
            ;&
        debian-*)
            if [[ "$SPREAD_SYSTEM" == ubuntu-14.04-* ]]; then
                # relying on dpkg as apt(-get) does not support installation from local files in trusty.
                dpkg -i --force-depends --auto-deconfigure --force-depends-version "$@"
                apt-get -f install -y
            else
                apt install -y "$@"
            fi
            ;;
        fedora-*)
            quiet dnf install -y "$@"
            ;;
        opensuse-*)
            quiet zypper instal "$@"
            ;;
        *)
            echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
            exit 1
            ;;
    esac
}

distro_install_package() {
    for pkg in "$@" ; do
        package_name=$(distro_name_package $pkg)
        # When we could not find a different package name for the distribution
        # we're running on we try the package name given as last attempt
        if [ -z "$package_name" ]; then
            package_name="$pkg"
        fi

        case "$SPREAD_SYSTEM" in
            ubuntu-*)
                ;&
            debian-*)
                apt-get install -y $package_name
                ;;
            fedora-*)
                dnf install -y $package_name
                ;;
            opensuse-*)
                zypper install $package_name
                ;;
            *)
                echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
                exit 1
                ;;
        esac
    done
}

distro_purge_package() {
    for pkg in "$@" ; do
        package_name=$(distro_name_package $pkg)
        # When we could not find a different package name for the distribution
        # we're running on we try the package name given as last attempt
        if [ -z "$package_name" ]; then
            package_name="$pkg"
        fi

        case "$SPREAD_SYSTEM" in
            ubuntu-*)
                ;&
            debian-*)
                quiet apt-get remove -y --purge -y $package_name
                ;;
            fedora-*)
                quiet dnf remove -y $package_name
                ;;
            opensuse-*)
                quiet zypper remove $package_name
                ;;
            *)
                echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
                exit 1
                ;;
        esac
    done
}

distro_update_package_db() {
    case "$SPREAD_SYSTEM" in
        ubuntu-*)
            ;&
        debian-*)
            quiet apt-get update
            ;;
        fedora-*)
            quiet dnf update -y
            ;;
        opensuse-*)
            quiet zypper update
            ;;
        *)
            echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
            exit 1
            ;;
    esac
}

distro_auto_remove_packages() {
    case "$SPREAD_SYSTEM" in
        ubuntu-*)
            ;&
        debian-*)
            quiet apt-get -y autoremove
            ;;
        fedora-*)
            ;&
        opensuse-*)
            ;;
        *)
            echo "ERROR: Unsupported distribution '$SPREAD_SYSTEM'"
            exit 1
            ;;
    esac
}