#!/bin/bash
set -e
readonly INSTALLATION_DIR=/opt/hailo/tappas

# Extract GStramer version used
GSTREAMER_VERSION=$(gst-launch-1.0 --gst-version | awk '{print $NF}' | cut -d. -f1,2)
num_cores_to_use=$(($(nproc)/2))

if [[ -z "$TAPPAS_WORKSPACE" ]]; then
  export TAPPAS_WORKSPACE=$(dirname "$(dirname "$(realpath "$0")")")
  echo "No TAPPAS_WORKSPACE in environment found, using the default one $TAPPAS_WORKSPACE"
fi



function install_plugins_good() {
  if [[ ! $GSTREAMER_VERSION == @(1.14|1.16) ]]; then 
  	return 0
  fi
	
  pushd ${TAPPAS_WORKSPACE}/sources/
  git clone --depth 1 -b ${GSTREAMER_VERSION} https://github.com/GStreamer/gst-plugins-good.git
  pushd gst-plugins-good

  # Patch rtsp-plugins-good
  git apply ${TAPPAS_WORKSPACE}/core/patches/rtsp/rtspsrc_stream_id_path.patch

  # Build plugins-good
  meson build --prefix ${INSTALLATION_DIR}
  ninja -j $num_cores_to_use -C build
  sudo env "PATH=$PATH" ninja -j $num_cores_to_use -C build install
  popd
  popd

}

function install_gst_instruments() {
  # Build debug plugins
  pushd ${TAPPAS_WORKSPACE}/sources/
  git clone --depth 1 -b 0.3.1 https://github.com/kirushyk/gst-instruments.git
  pushd gst-instruments
  meson build -Dui=disabled --prefix ${INSTALLATION_DIR}
  ninja -j $num_cores_to_use -C build
  sudo env "PATH=$PATH" ninja -j $num_cores_to_use -C build install
  popd
  popd

}

install_plugins_good

# gst_instruments is optional 
# We dont want to fail our install in case it fails
install_gst_instruments || true
