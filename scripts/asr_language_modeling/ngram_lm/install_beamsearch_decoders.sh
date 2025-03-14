#!/usr/bin/env bash
# Copyright (c) 2022, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Use this script to install KenLM, OpenSeq2Seq decoder, Flashlight decoder
shopt -s expand_aliases
# echo "Script is located in: $(dirname "$(realpath "$0")")"

# NEMO_PATH=/tmp/pip-req-build-e0_1v5kj/NeMo  # Path to NeMo folder: /workspace/nemo if you use NeMo/Dockerfile
# if [ "$#" -eq 1 ]; then
#   NEMO_PATH=$1
# fi
KENLM_MAX_ORDER=10 # Maximum order of KenLM model, also specified in the setup_os2s_decoders.py

# if [ -d "$NEMO_PATH" ]; then
#   echo "The folder '$NEMO_PATH' exists."
# else
#   echo "Error: The folder '$NEMO_PATH' does not exist. Specify it as a first command line positional argument!"
#   exit 1
# fi
echo "Script in: $(pwd)"
NEMO_PATH=$(pwd)
cd $NEMO_PATH
echo "Now in: $(pwd)"

if [ $(id -u) -eq 0 ]; then
  alias aptupdate='apt-get update'
  alias b2install='./b2'
else
  alias aptupdate='sudo apt-get update'
  alias b2install='sudo ./b2'
fi

sudo apt install -y libstdc++6
sudo apt install -y cmake
sudo apt install -y libboost-all-dev
sudo apt install -y ffmpeg
sudo apt install -y swig
sudo aptupdate && sudo apt-get upgrade -y && sudo apt-get install -y swig liblzma-dev && rm -rf /var/lib/apt/lists/* # liblzma needed for flashlight decoder

# install Boost package for KenLM
wget https://boostorg.jfrog.io/artifactory/main/release/1.80.0/source/boost_1_80_0.tar.bz2 --no-check-certificate && sudo tar --bzip2 -xf $NEMO_PATH/boost_1_80_0.tar.bz2 && cd boost_1_80_0 && ./bootstrap.sh && b2install --layout=tagged link=static,shared threading=multi,single install -j4 && cd .. || echo FAILURE
export BOOST_ROOT=$NEMO_PATH/boost_1_80_0

sudo git clone https://github.com/NVIDIA/OpenSeq2Seq
cd OpenSeq2Seq
sudo git checkout ctc-decoders
cd ..
sudo mv OpenSeq2Seq/decoders $NEMO_PATH/
sudo rm -rf OpenSeq2Seq
sudo chown $(whoami):$(whoami) $NEMO_PATH/decoders
cd $NEMO_PATH/decoders
sudo cp $NEMO_PATH/scripts/installers/setup_os2s_decoders.py ./setup.py
./setup.sh

# install KenLM
cd $NEMO_PATH/decoders/kenlm/build && sudo cmake -DKENLM_MAX_ORDER=$KENLM_MAX_ORDER .. && sudo make -j2
cd $NEMO_PATH/decoders/kenlm
python setup.py install --max_order=$KENLM_MAX_ORDER
export KENLM_LIB=$NEMO_PATH/decoders/kenlm/build/bin
export KENLM_ROOT=$NEMO_PATH/decoders/kenlm
cd ..

# install Flashlight
sudo git clone https://github.com/flashlight/text && cd text
python setup.py bdist_wheel
pip install dist/*.whl
cd ..
