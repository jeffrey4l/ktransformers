FROM node:20.16.0 as web_compile
WORKDIR /home
copy . /home/ktransformers
RUN <<EOF
cd ktransformers/ktransformers/website/ &&
npm install @vue/cli &&
npm run build &&
rm -rf node_modules
EOF



FROM pytorch/pytorch:2.5.1-cuda12.1-cudnn9-devel as compile_server
# FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel as compile_server
# FROM pytorch/pytorch:2.6.0-cuda11.8-cudnn9-devel as compile_server
# FROM pytorch/pytorch:2.0.1-cuda11.7-cudnn8-devel as compile_server

ARG CPU_INSTRUCT=NATIVE
WORKDIR /workspace
ENV CUDA_HOME /usr/local/cuda
COPY --from=web_compile /home/ktransformers /workspace/ktransformers
RUN <<EOF
apt update -y &&  apt install -y  --no-install-recommends \
    git \
    wget \
    vim \
    gcc \
    g++ \
    cmake && 
rm -rf /var/lib/apt/lists/* &&
cd ktransformers &&
git submodule init &&
git submodule update &&
pip install ninja pyproject numpy cpufeature &&
pip install flash-attn &&
CPU_INSTRUCT=${CPU_INSTRUCT} KTRANSFORMERS_FORCE_BUILD=TRUE TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.7;8.9;9.0+PTX" pip install . --no-build-isolation --verbose &&
pip cache purge &&
cp /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /opt/conda/lib/
EOF

ENTRYPOINT ["tail", "-f", "/dev/null"]
