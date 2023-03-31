SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $SCRIPT_DIR/airootfs/root
git clone -b K-Arch-Iso https://github.com/k-arch27/archscript
mkarchiso -v $SCRIPT_DIR
