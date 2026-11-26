#!/usr/bin/env bash
# LM4FBS BEGIN ADDITION — Install stock OpenBSD on a new disk for each binary test.
set -euo pipefail

payload=$(realpath "${1:?usage: run.sh PAYLOAD_DIRECTORY GUEST_SCRIPT}")
script=${2:?missing guest script relative to payload}
[[ $script =~ ^[[:alnum:]_./-]+$ && $script != /* && $script != *..* && -f $payload/$script ]]
work=$(mktemp -d)
http_pid=
vm_pid=
console_pid=
cleanup() {
    local status=$?
    if (( status != 0 )) && [[ -f $work/console.log ]]; then
        tail -c 12000 "$work/console.log" >&2
    fi
    for pid in "$vm_pid" "$http_pid" "$console_pid"; do
        if [[ -n $pid ]]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi
    done
    rm -rf "$work"
}
trap cleanup EXIT

# Only immutable installer media may be reused. Verify it even when cached.
media=${OPENBSD_MEDIA_DIR:-$work/media}
mkdir -p "$media" "$work/tftp/etc" "$work/http"
release=https://cdn.openbsd.org/pub/OpenBSD/8.0/amd64
for file in SHA256.sig install80.iso pxeboot bsd.rd; do
    if [[ ! -f $media/$file ]]; then
        echo "Downloading OpenBSD 8.0/amd64 $file"
        curl --fail --location --silent --show-error --retry 3 "$release/$file" -o "$work/download"
        mv "$work/download" "$media/$file"
    fi
done
# OpenBSD's published openbsd-80-base.pub from https://www.openbsd.org/80.html
cat > "$work/release.pub" <<'KEY'
untrusted comment: OpenBSD 8.0 base public key
RWSMSt0erHTctUxq2JDAgQRo64ztikp8JvQeiSPte3NZ0Geou0TkTEiE
KEY
(cd "$media" && signify-openbsd -C -p "$work/release.pub" -x SHA256.sig install80.iso pxeboot bsd.rd)

# The stock PXE loader honors boot.conf, allowing a serial console without
# remastering the ISO or changing its signed installer kernel and sets.
cp "$media/pxeboot" "$media/bsd.rd" "$work/tftp/"
printf '%s\n' 'stty com0 115200' 'set tty com0' 'boot tftp:bsd.rd' > "$work/tftp/etc/boot.conf"
ssh-keygen -q -t ed25519 -N '' -f "$work/guest-key"
cat > "$work/http/install.conf" <<ANSWERS
System hostname = libremerge-test
Network interface to configure = vio0
IPv4 address for vio0 = autoconf
IPv6 address for vio0 = none
Network interface to configure = done
Password for root account = *************
Public ssh key for root account = $(cat "$work/guest-key.pub")
Start sshd(8) by default = yes
Do you expect to run the X Window System = yes
Setup a user = no
Allow root ssh login = prohibit-password
Which disk is the root disk = sd0
Encrypt the root disk = no
Location of sets = cd0
Set name(s) = -comp* -game*
Set name(s) = done
Directory does not contain SHA256.sig. Continue without verification = yes
Location of sets = done
What timezone are you in = UTC
ANSWERS

# The entire mounted ISO has already been verified. Serve only the public
# installer answers on loopback, which the guest sees as 10.0.2.2.
python3 -m http.server 18880 --bind 127.0.0.1 --directory "$work/http" >"$work/http.log" 2>&1 &
http_pid=$!
qemu-img create -f qcow2 "$work/system.qcow2" 20G
mkfifo "$work/serial.in" "$work/serial.out"
exec 3<>"$work/serial.in"
cat "$work/serial.out" >"$work/console.log" &
console_pid=$!
qemu-system-x86_64 -machine accel=kvm:tcg -smp 2 -m 2048 -display none -monitor none \
    -serial "pipe:$work/serial" -boot order=c,once=n \
    -drive "file=$work/system.qcow2,if=virtio,format=qcow2" -cdrom "$media/install80.iso" \
    -nic "user,model=virtio-net-pci,tftp=$work/tftp,bootfile=pxeboot,hostfwd=tcp:127.0.0.1:2222-:22" &
vm_pid=$!

# Give the installer an explicit response URL. No privileged host port or
# external DHCP server is required. The installer reboots onto the new disk.
deadline=$((SECONDS + 1800))
guest_running() {
    if ! kill -0 "$vm_pid" || ! kill -0 "$http_pid" || (( SECONDS >= deadline )); then
        echo 'OpenBSD did not finish installing and starting SSH.' >&2
        exit 1
    fi
    if grep -Fq 'failed; check /tmp/ai/ai.log' "$work/console.log"; then
        echo 'The OpenBSD installer reported an error.' >&2
        exit 1
    fi
}
echo 'Starting a clean OpenBSD installation from the verified release media.'
until grep -Fq 'Response file location?' "$work/console.log"; do guest_running; sleep 2; done
printf '%s\r' 'http://10.0.2.2:18880/install.conf' >&3
ssh_guest=(ssh -p 2222 -i "$work/guest-key" -o IdentitiesOnly=yes -o BatchMode=yes
    -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new -o "UserKnownHostsFile=$work/known_hosts"
    root@127.0.0.1)
until "${ssh_guest[@]}" true 2>/dev/null; do guest_running; sleep 5; done

"${ssh_guest[@]}" /bin/sh -se <<'OPENBSD'
uname -a
test "$(uname -r)" = 8.0
test "$(machine -a)" = amd64
OPENBSD
tar -C "$payload" -cf - . | "${ssh_guest[@]}" 'mkdir /root/test && cd /root/test && tar -xf -'
"${ssh_guest[@]}" "cd /root/test && exec /bin/sh ./$script"
# LM4FBS END
