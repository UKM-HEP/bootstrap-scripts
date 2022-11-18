#! /usr/bin/env bash

# Rivet bootstrapping / installation script for version 3.0.2

test -z "$BUILD_PREFIX" && BUILD_PREFIX="$PWD"
test -z "$INSTALL_PREFIX" && INSTALL_PREFIX="$PWD/local"
test -z "$MAKE" && MAKE="make -j12"

test -z "$INSTALL_HEPMC2" && INSTALL_HEPMC2="1"
test -z "$INSTALL_HEPMC3" && INSTALL_HEPMC3="1"
test -z "$INSTALL_FASTJET" && INSTALL_FASTJET="1"
test -z "$INSTALL_FJCONTRIB" && INSTALL_FJCONTRIB="1"
test -z "$INSTALL_LHAPDF6" && INSTALL_LHAPDF6="1"
test -z "$INSTALL_YODA" && INSTALL_YODA="1"
test -z "$INSTALL_RIVET" && INSTALL_RIVET="1"
test -z "$INSTALL_OPENLOOP" && INSTALL_OPENLOOP="1"
test -z "$INSTALL_SHERPA" && INSTALL_SHERPA="1"

test -z "$HEPMC2_VERSION" && HEPMC2_VERSION="2.06.10"
test -z "$HEPMC3_VERSION" && HEPMC3_VERSION="3.2.5"
test -z "$FASTJET_VERSION" && FASTJET_VERSION="3.4.0"
test -z "$FJCONTRIB_VERSION" && FJCONTRIB_VERSION="1.041"
test -z "$LHAPDF6_VERSION" && LHAPDF6_VERSION="6.4.0"
test -z "$YODA_VERSION" && YODA_VERSION="1.9.4"
test -z "$RIVET_VERSION" && RIVET_VERSION="3.1.5"
test -z "$OPENLOOP_VERSION" && OPENLOOP_VERSION="2.1.2"
test -z "$SHERPA_VERSION" && SHERPA_VERSION="2.2.12"

## Rivet needs C++11 now: first run a simple test for that
test -z "$CXX" && CXX="g++"
echo "int main() { return 0; }" > cxxtest.cc
CXX11=1
$CXX -std=c++11 cxxtest.cc -o cxxtest &> /dev/null || CXX11=0
rm -f cxxtest cxxtest.cc
if [[ "$CXX11" -ne 1 ]]; then
    echo "$CXX does not accept the -std=c++11 flag. You need C++ to build Rivet: exiting installation :-("
    exit 1
else
    echo "$CXX accepts the -std=c++11 flag: hurrah! Continuing installation..."
    echo
fi

## Paths for the case of existing installations
test -z "$HEPMC2PATH" && HEPMC2PATH="/usr"
test -z "$HEPMC3PATH" && HEPMC3PATH="/usr"
test -z "$FASTJETPATH" && FASTJETPATH="/usr"
test -z "$YODAPATH" && YODAPATH="/usr"
test -z "$RIVETPATH" && RIVETPATH="/usr"
test -z "$LHAPDF6PATH" && LHAPDF6PATH="/usr"
test -z "$OPENLOOPPATH" && OPENLOOPPATH="/usr"
test -z "$SHERPAPATH" && SHERPAPATH="/usr"

test -z "$RIVET_CONFFLAGS" && RIVET_CONFFLAGS="" #--enable-unvalidated
test -z "$YODA_CONFFLAGS" && YODA_CONFFLAGS=""

if [[ "$INSTALL_RIVETDEV" -eq "1" ]]; then
    ## For rivetdev we skip the normal yoda/rivet installation
    INSTALL_YODA="0"
    INSTALL_RIVET="0"
    ## Might need to install some extra toolkit bits for dev mode
    test -z "$INSTALL_AUTOTOOLS" && INSTALL_AUTOTOOLS="1"
    test -z "$INSTALL_HG" && INSTALL_HG="1"
    test -z "$INSTALL_CYTHON" && INSTALL_CYTHON="1"
fi

## Disable asserts for production running
export CPPFLAGS="$CPPFLAGS -DNDEBUG"

###############

echo "Running Sherpa bootstrap script"
sleep 3
echo "Building :"

[ "$INSTALL_HEPMC2"    -eq 1 ] && echo "HepMC2    : $HEPMC2_VERSION"
[ "$INSTALL_HEPMC3"    -eq 1 ] && echo "HepMC3    : $HEPMC3_VERSION"
[ "$INSTALL_FASTJET"   -eq 1 ] && echo "FastJet   : $FASTJET_VERSION"
[ "$INSTALL_FJCONTRIB" -eq 1 ] && echo "Fjcontrib : $FJCONTRIB_VERSION"
[ "$INSTALL_LHAPDF6"   -eq 1 ] && echo "LHAPDF    : $LHAPDF6_VERSION"
[ "$INSTALL_YODA"      -eq 1 ] && echo "Yoda      : $YODA_VERSION"
[ "$INSTALL_RIVET"     -eq 1 ] && echo "Rivet     : $RIVET_VERSION"
[ "$INSTALL_OPENLOOP"  -eq 1 ] && echo "Openloop  : $OPENLOOP_VERSION"
[ "$INSTALL_SHERPA"    -eq 1 ] && echo "Sherpa    : $SHERPA_VERSION"

echo ""

## Immediate exit on a command (group) failure and optional debug mode
set -e
test -n "$DEBUG" && set -x
export PATH=$INSTALL_PREFIX/bin:$PATH

function wget_untar { wget --no-check-certificate -c $1 -O- | tar xz; }
function conf { ./configure --prefix=$INSTALL_PREFIX "$@"; }
function addbashrc {
    TEST=$(grep -q "$@" ${HOME}/.bashrc; echo $?)
    if [[ "$TEST" -eq "1" ]]; then
        echo "$@" >> ~/.bashrc
    fi
    }
function mmi { $MAKE "$@" && $MAKE install; }

## Make installation directory, with an etc subdir so Rivet etc. will install bash completion scripts
mkdir -p $INSTALL_PREFIX/etc/bash_completion.d

## prepare environment
addbashrc "export PATH=${INSTALL_PREFIX}/bin:\$PATH"
source ~/.bashrc

## Install HepMC2
if [[ "$INSTALL_HEPMC2" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d HepMC-$HEPMC2_VERSION || wget_untar https://hepmc.web.cern.ch/hepmc/releases/hepmc$HEPMC2_VERSION.tgz
    mkdir -p hepmc2-build; cd hepmc2-build
    cmake -Dmomentum:STRING=GEV -Dlength:STRING=MM -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX ../HepMC-$HEPMC2_VERSION
    mmi
    HEPMC2PATH=$INSTALL_PREFIX
fi

## Install HepMC3
if [[ "$INSTALL_HEPMC3" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d HepMC3-$HEPMC3_VERSION || wget_untar http://hepmc.web.cern.ch/hepmc/releases/HepMC3-$HEPMC3_VERSION.tar.gz
    mkdir -p hepmc3-build; cd hepmc3-build
    cmake -DHEPMC3_ENABLE_ROOTIO=ON \
	  -DROOT_DIR=`root-config --prefix` \
	  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
	  -DHEPMC3_Python_SITEARCH39=$INSTALL_PREFIX \
	  -DHEPMC3_Python_SITEARCH27=$INSTALL_PREFIX \
	  ../HepMC3-$HEPMC3_VERSION
    mmi
    HEPMC3PATH=$INSTALL_PREFIX
fi

## Install Lhapdf6
if [[ "$INSTALL_LHAPDF6" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d LHAPDF-$LHAPDF6_VERSION || wget_untar http://www.hepforge.org/archive/lhapdf/LHAPDF-$LHAPDF6_VERSION.tar.gz
    cd LHAPDF-$LHAPDF6_VERSION
    conf 
    mmi
    LHAPDF6PATH=$INSTALL_PREFIX
fi

## Install FastJet
if [[ "$INSTALL_FASTJET" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d fastjet-$FASTJET_VERSION || wget_untar http://www.fastjet.fr/repo/fastjet-$FASTJET_VERSION.tar.gz
    cd fastjet-$FASTJET_VERSION
    conf --enable-shared --disable-auto-ptr --enable-allcxxplugins
    mmi
    FASTJETPATH=$INSTALL_PREFIX
fi

## Install fjcontrib
if [[ "$INSTALL_FJCONTRIB" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d fjcontrib-$FJCONTRIB_VERSION || wget_untar http://fastjet.hepforge.org/contrib/downloads/fjcontrib-$FJCONTRIB_VERSION.tar.gz
    cd fjcontrib-$FJCONTRIB_VERSION
    ./configure --fastjet-config=$FASTJETPATH/bin/fastjet-config CXXFLAGS=-fPIC # fastjet-config already contains INSTALL_PREFIX
    mmi fragile-shared-install
    # does not need FJCONTRIBPATH because the relevant includes/libraries are merged with regular FastJet structure
fi

## Install YODA
if [[ "$INSTALL_YODA" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d YODA-$YODA_VERSION || wget_untar http://www.hepforge.org/archive/yoda/YODA-$YODA_VERSION.tar.gz
    cd YODA-$YODA_VERSION
    conf $YODA_CONFFLAGS --with-zlib="/home/shoh/anaconda3"
    mmi
    cp yodaenv.sh $INSTALL_PREFIX/yodaenv.sh
    YODAPATH=$INSTALL_PREFIX
fi

## Install Rivet
if [[ "$INSTALL_RIVET" -eq "1" ]]; then
    cd $BUILD_PREFIX
    test -d Rivet-$RIVET_VERSION || wget_untar http://www.hepforge.org/archive/rivet/Rivet-$RIVET_VERSION.tar.gz
    cd Rivet-$RIVET_VERSION
    #--with-hepmc3=$HEPMC3PATH \
    conf $RIVET_CONFFLAGS \
         --with-yoda=$YODAPATH \
	 --with-hepmc=$HEPMC2PATH \
         --with-fastjet=$FASTJETPATH \
	 --with-zlib="/home/shoh/anaconda3"
    mmi
    RIVETPATH=$INSTALL_PREFIX
    cp rivetenv.sh rivetenv.csh $INSTALL_PREFIX/
    #source $INSTALL_PREFIX/rivetenv.sh
fi

## Install Openloop
if [[ "$INSTALL_OPENLOOP" -eq "1" ]]; then
#    cd $BUILD_PREFIX
#    test -d OpenLoops-$OPENLOOP_VERSION || wget_untar https://openloops.hepforge.org/downloads/OpenLoops-$OPENLOOP_VERSION.tar.gz
#    cd OpenLoops-$OPENLOOP_VERSION
#    ./scons
#    OPENLOOPPATH=$BUILD_PREFIX/OpenLoops-$OPENLOOP_VERSION

    # switch to github openloops (master)
    cd $BUILD_PREFIX
    test -d OpenLoops-$OPENLOOP_VERSION || git clone https://gitlab.com/openloops/OpenLoops.git -b OpenLoops-$OPENLOOP_VERSION OpenLoops-$OPENLOOP_VERSION
    cd OpenLoops-$OPENLOOP_VERSION
    #git checkout OpenLoops-$OPENLOOP_VERSION && git checkout -b OpenLoops-$OPENLOOP_VERSION
    scons
    #./openloops libinstall update
    ./openloops libinstall pphhjj2 #lhc.coll
    
fi

## Install Sherpa
if [[ "$INSTALL_SHERPA" -eq "1" ]]; then
    
    cd $BUILD_PREFIX
    #test -d SHERPA-MC-$SHERPA_VERSION || wget_untar https://sherpa.hepforge.org/downloads/SHERPA-MC-$SHERPA_VERSION.tar.gz
    #cd SHERPA-MC-$SHERPA_VERSION/AddOns/MCFM; ./install_mcfm.sh
    #--enable-mcfm=$BUILD_PREFIX/SHERPA-MC-$SHERPA_VERSION/AddOns/MCFM\
    cd $BUILD_PREFIX/SHERPA-MC-$SHERPA_VERSION
    # --enable-openloops=$BUILD_PREFIX/OpenLoops-${OPENLOOP_VERSION}
    conf --enable-mpi \
	 --enable-pyext \
	 --enable-ufo \
	 --enable-analysis \
	 --enable-lhole \
	 --enable-root=`root-config --prefix` \
         --enable-lhapdf=`lhapdf-config --prefix` \
	 --enable-hepmc2=$BUILD_PREFIX/local \
	 --enable-hepmc3root \
	 --enable-hepmc3=`HepMC3-config --prefix` \
	 --enable-rivet=`rivet-config --prefix` \
	 --enable-fastjet=`fastjet-config --prefix` \
	 --enable-openloops=$BUILD_PREFIX/OpenLoops-${OPENLOOP_VERSION} \
	 --enable-gzip \
	 --enable-pythia \
	 --with-sqlite3=install
    
    #Avoid building in Manual and Example directory    
    sed -i 's,AddOns \\,AddOns,g' Makefile
    sed -i 's,Manual \\,,g' Makefile
    sed -i -e 's,Examples,,g' Makefile

    mmi
fi

## Following block for dev mode only -- non-developers should ignore
if [[ "$INSTALL_RIVETDEV" -eq "1" ]]; then
    ## Install autotools
    if [[ "$INSTALL_AUTOTOOLS" -eq "1" ]]; then
        cd $BUILD_PREFIX
        function _build_autotool() {
            name=$1-$2
            if [ ! -e $name ]; then wget_untar http://ftpmirror.gnu.org/$1/$name.tar.gz; fi
            cd $name
            ./configure --prefix=$INSTALL_PREFIX
            mmi -j12
            cd ..
        }
        test -e $INSTALL_PREFIX/bin/m4       || { echo; echo "Building m4"; _build_autotool m4 1.4.18; }
        test -e $INSTALL_PREFIX/bin/autoconf || { echo; echo "Building autoconf"; _build_autotool autoconf 2.69; }
        test -e $INSTALL_PREFIX/bin/automake || { echo; echo "Building automake"; _build_autotool automake 1.16.1; }
        test -e $INSTALL_PREFIX/bin/libtool  || { echo; echo "Building libtool"; _build_autotool libtool 2.4.6; }
    fi

    ## Install hg
    if [[ "$INSTALL_HG" -eq "1" ]]; then
        cd $BUILD_PREFIX
        HG_VERSION=4.6.2
        test -d mercurial-$HG_VERSION || wget_untar http://mercurial-scm.org/release/mercurial-$HG_VERSION.tar.gz
        cd mercurial-$HG_VERSION
        $MAKE PREFIX=$INSTALL_PREFIX install-bin
    fi

    ## Install Cython
    if [[ "$INSTALL_CYTHON" -eq "1" ]]; then
        cd $BUILD_PREFIX
        CYTHON_VERSION=0.28.5
        test -d cython-$CYTHON_VERSION || { wget https://github.com/cython/cython/archive/$CYTHON_VERSION.tar.gz -O - | tar xz; }
        export PATH=$BUILD_PREFIX/cython-$CYTHON_VERSION/bin:$PATH
        export PYTHONPATH=$BUILD_PREFIX/cython-$CYTHON_VERSION:$PYTHONPATH
    fi

    ## Install dev YODA
    cd $BUILD_PREFIX
    test -d yoda || hg clone https://phab.hepforge.org/source/yodahg/yoda -b release-1-7 --insecure
    cd yoda
    hg pull -u --insecure
    autoreconf -i
    conf $YODA_CONFFLAGS --with-zlib="/home/shoh/anaconda3"
    mmi
    cp yodaenv.sh $INSTALL_PREFIX/yodaenv.sh
    YODAPATH=$INSTALL_PREFIX

    ## Install dev Rivet
    cd $BUILD_PREFIX
    test -d rivet || hg clone https://phab.hepforge.org/source/rivethg/rivet -u release-3-0-x --insecure
    cd rivet
    hg pull -u --insecure
    autoreconf -i
    conf $RIVET_CONFFLAGS \
        --with-yoda=$YODAPATH \
        #--with-hepmc=$HEP2MCPATH \
	--with-hepmc3=$HEPMC2PATH \
        --with-fastjet=$FASTJETPATH \
	--with-zlib="/home/shoh/anaconda3"
    mmi
    cp rivetenv.sh rivetenv.csh $INSTALL_PREFIX/
fi

## Announce the build success
echo; echo "All done. Now set some variables in your shell"
addbashrc "export SHERPA_ROOT_DIR=${INSTALL_PREFIX}"
addbashrc "export SHERPA_INCLUDE_PATH=$SHERPA_ROOT_DIR/include/SHERPA-MC"
addbashrc "export SHERPA_SHARE_PATH=$SHERPA_ROOT_DIR/share/SHERPA-MC"
addbashrc "export SHERPA_LIBRARY_PATH=$SHERPA_ROOT_DIR/lib/SHERPA-MC"
addbashrc "export LD_LIBRARY_PATH=$SHERPA_LIBRARY_PATH:\$LD_LIBRARY_PATH"

source ~/.bashrc
