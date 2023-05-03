#!/bin/bash

# Function to set DNS
function setDns(){
    echo "Setting DNS..."
    # Retrieve public IP address
    ip=$(curl -s http://ip.sb)
    if [ $? -ne 0 ]; then
        echo "Error retrieving IP address."
        return 1
    fi
    # Retrieve DNS servers
    dns=$(curl -s https://www.yifei.cool:8080/jeecg-boot/servic/getDns?ip=$ip)
    if [ $? -ne 0 ]; then
        echo "Error retrieving DNS servers."
        return 1
    fi
    # Extract DNS server IP addresses
    dnss=($(echo $dns | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}'))
    if [ -z "$dnss" ]; then
        echo "dnss is empty"
    else
        # Write DNS server IP addresses to /etc/resolv.conf
        echo -e "nameserver ${dnss[0]}\nnameserver ${dnss[1]}" >/etc/resolv.conf
        if [ $? -ne 0 ]; then
            echo "Error writing to resolv.conf."
            return 1
        fi
    fi
    echo "DNS set."
    return 0
}

# Function to set MTU
function setMtu(){
    file=/etc/sysconfig/network-scripts/ifcfg-eth0
    mtu=$(grep MTU $file)
    if [ -z "$mtu" ]; then
        echo "MTU=1500" >> $file
    else
        sed -i "s/$mtu/MTU=1500/" $file
    fi
    systemctl restart network
}

# Function to install gost3
function installGost3(){
    # Set MTU and DNS
    setMtu
    setDns
    # Clone gost3 repository and install it
    git clone https://github.com/1443213244/gost3.git
    cd gost3
    sudo bash install.sh
    sudo sed -i '/\/usr\/local\/bin\/gost.sh/d' /etc/rc.d/rc.local
    rm -rf /usr/local/bin/gost.sh
}

# Main script
echo "Starting installation..."
# Install gost3
installGost3
if [ $? -ne 0 ]; then
    echo "Error installing gost3."
    exit 1
fi
echo "Installation completed successfully."
