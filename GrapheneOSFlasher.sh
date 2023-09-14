#!/bin/bash
download () {
	read -p "Would you like to proceed to download GrapheneOS? [y/N]: " yn
	if [ $yn = y ]; then
		factoryzipurl=$(curl -q https://grapheneos.org/releases | grep -o https://releases\.grapheneos\.org/$codename-factory-[0-9.]*\.zip | head -1)
		factoryzipsigurl=$(curl -q https://grapheneos.org/releases | grep -o https://releases\.grapheneos\.org/$codename-factory-[0-9.]*\.zip.sig | head -1)
		factoryzip=$(echo "$factoryzipurl" | grep -o $codename-factory-[0-9.]*\.zip)
		factoryzipsig=$(echo "$factoryzipsigurl" | grep -o $codename-factory-[0-9.]*\.zip.sig)
		factorydir=$(echo "$factoryzip" | grep -o $codename-factory-[0-9.]*)
		cd /tmp/
		curl -O https://releases.grapheneos.org/factory.pub
		curl -O $factoryzipurl
		curl -O $factoryzipsigurl
		if signify -Cqp factory.pub -x $factoryzipsig && echo verified; then
			bsdtar xvf $factoryzip
			install
		else
			unverified
		fi
	elif [ $yn = n ]; then
		printf "Maybe next time!"
		exit
	else
		download
	fi
}
install () {
	read -p "Would you like to proceed to unlock the bootloader and install GrapheneOS? [y/N]: " yn
	if [ $yn = y ]; then
		printf "You will need to confirm on the device and this will wipe all data. Use one of the volume buttons to switch the selection to accepting it and the power button to confirm.\n\n"
		sleep 2
		fastboot flashing unlock
		printf "Once your bootloader is unlocked, you may flash GrapheneOS.\n\n"
		sleep 2
		read -n 1 -s -r -p "Press any key to continue"
		bash $factorydir/flash-all.sh
		printf "Once you're done flashing, you may relock the bootloader.\n\n"
		sleep 2
		read -n 1 -s -r -p "Press any key to continue"
		fastboot flashing lock
		printf "\n\nOEM unlocking can be disabled again in the developer settings menu within the operating system after booting it up again.\n\n"
		sleep 2
		printf "After disabling OEM unlocking, we recommend disabling developer options as a whole for a device that's not being used for app or OS development.\n\n"
		sleep 2
		printf "You may verify your GrapheneOS installation using hardware-based attestation with the instructions at https://attestation.app/tutorial or with the verified boot key hash at https://grapheneos.org/install/cli#verified-boot-key-hash"
		exit 0
	elif [ $yn = n ]; then
		printf "Maybe next time!"
		exit
	else
		install
	fi
}
unverified () {
	read -p "Your archive can't be verified! Would you like to delete the 3 associated files?" yn
	if [ $yn = y ]; then
		rm -r factory.pub $factoryzip $factoryzipsig
		exit
	elif [ $yn = n ]; then
		printf "Operation aborted!"
		exit
	else
		unverified
	fi
}
printf "As prerequisites, you will need adb and Fastboot 34.0.4+(some distributions include these in the same package, such as android-tools), android udev rules, bsdtar, curl, signify(or signifybsd for Debian)\n\n"
sleep 2
read -n 1 -s -r -p "Press any key to continue"
sleep 2
printf "\n\nYou will need to enable USB debugging and OEM unlocking on your device\n\n"
sleep 2
printf "Enable the developer options menu by going to Settings ➔ About phone/tablet and repeatedly pressing the build number menu entry until developer mode is enabled.\n\n"
sleep 2
printf "Next, go to Settings ➔ System ➔ Developer options and toggle on the 'OEM unlocking' and 'USB debugging' settings. On device model variants (SKUs) which support being sold as locked devices by carriers, enabling 'OEM unlocking' requires internet access so that the stock OS can check if the device was sold as locked by a carrier.\n\n"
sleep 2
printf "For the Pixel 6a, OEM unlocking won't work with the version of the stock OS from the factory. You need to update it to the June 2022 release or later via an over-the-air update. After you've updated it you'll also need to factory reset the device to fix OEM unlocking.\n\n"
sleep 2
read -n 1 -s -r -p "Press any key to continue"
printf "\n\n"
typeset -l yn
if adb devices -l | grep -oq 'flame\|coral\|sunfish\|bramble\|redfin\|barbet\|oriole\|raven\|bluejay\|panther\|cheetah\|lynx\|tangorpro\|felix'; then
	codename=$(adb devices -l | grep -o 'flame\|coral\|sunfish\|bramble\|redfin\|barbet\|oriole\|raven\|bluejay\|panther\|cheetah\|lynx\|tangorpro\|felix' | head -1)
	download
else
	printf "No supported devices detected. Operation aborted."
	exit 1
fi