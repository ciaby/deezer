#!/bin/sh

# Maintainer: Sibren Vasse <arch@sibrenvasse.nl>
# Contributor: Ilya Gulya <ilyagulya@gmail.com>
pkgname="deezer"
pkgver=5.30.50
srcdir="$PWD"

install_dependencies() {
    apt install p7zip imagemagick nodejs wget
    npm install -g electron@^6 --unsafe-perm=true
    npm install -g --engine-strict asar
    npm install -g prettier
}

prepare() {
    # Download installer
    wget "https://www.deezer.com/desktop/download/artifact/win32/x86/$pkgver" -O "$pkgname-$pkgver-setup.exe"
    # Extract app from installer
    7z x -so $pkgname-$pkgver-setup.exe "\$PLUGINSDIR/app-32.7z" >app-32.7z
    # Extract app archive
    7z x -y -bsp0 -bso0 app-32.7z

    # Extract png from ico container
    convert resources/win/app.ico resources/win/deezer.png

    cd resources/
    asar extract app.asar app

    cd "$srcdir/resources/app"
    mkdir -p resources/linux/
    install -Dm644 "$srcdir/resources/win/systray.png" resources/linux/

    prettier --write "build/*.js"
    # Hide to tray (https://github.com/SibrenVasse/deezer/issues/4)
    patch --forward --strip=1 --input="$srcdir/quit.patch"
    # Add start in tray cli option (https://github.com/SibrenVasse/deezer/pull/12)
    patch --forward --strip=1 --input="$srcdir/start-hidden-on-tray.patch"

    cd "$srcdir/resources/"
    asar pack app app.asar
}

package() {
    cd "$srcdir"
    mkdir -p "$pkgdir/usr/share/deezer"
    mkdir -p "$pkgdir/usr/share/applications"
    mkdir -p "$pkgdir/usr/bin/"
    for size in 16 32 48 64 128 256; do
        mkdir -p "$pkgdir/usr/share/icons/hicolor/${size}x${size}/apps/"
    done

    install -Dm644 resources/app.asar "$pkgdir/usr/share/deezer/"
    install -Dm644 resources/win/deezer-0.png "$pkgdir/usr/share/icons/hicolor/16x16/apps/deezer.png"
    install -Dm644 resources/win/deezer-1.png "$pkgdir/usr/share/icons/hicolor/32x32/apps/deezer.png"
    install -Dm644 resources/win/deezer-2.png "$pkgdir/usr/share/icons/hicolor/48x48/apps/deezer.png"
    install -Dm644 resources/win/deezer-3.png "$pkgdir/usr/share/icons/hicolor/64x64/apps/deezer.png"
    install -Dm644 resources/win/deezer-4.png "$pkgdir/usr/share/icons/hicolor/128x128/apps/deezer.png"
    install -Dm644 resources/win/deezer-5.png "$pkgdir/usr/share/icons/hicolor/256x256/apps/deezer.png"
    install -Dm644 "$pkgname.desktop" "$pkgdir/usr/share/applications/"
    install -Dm755 deezer "$pkgdir/usr/bin/"
}

install_dependencies && prepare && package
echo "Successfully installed Deezer Desktop!"
