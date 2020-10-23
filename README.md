# customized docker container for gpr invesitagtions
## 1. install docker on your machine

ubuntu:
https://docs.docker.com/engine/install/ubuntu/

windows
https://docs.docker.com/docker-for-windows/install/


## 2. pull image 
```bash
docker pull quay.io/manstetten/theia-gpr:latest
```

### 2.1 prepare working dirctory permissions
```bash
cd workingdir
sudo groupadd --gid 5555 theiaide # create new group 'theiaide'
sudo usermod -a -G theiaide $(id -un) # append current user to group 'theiaide'
sudo chown -R :theiaide ./  # change ownership to the new theiaide group
sudo chmod -R 775 ./ # make accessible 
sudo chmod g+s ./ # make all future content inherit ownership
```

## 3. start theia backend server
```bash
# cd into folder (working dirctory) where your project lives (do not start in Home-folder as a lot of file-precaching happens then)
docker run --init -it -p 3000:3000 -v "$(pwd):/home/project:cached" quay.io/manstetten/theia-gpr:latest  
# when running memory sanitizer or debugger you need to launch
docker run --init -it -p 3000:3000 --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v "$(pwd):/home/project:cached" quay.io/manstetten/theia-gpr:latest 
```

### 4. when also using X
```bash
# allow local user access to xhost (for X)
sudo xhost +local:root 
# start docker
docker run --init -it --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -p 3001:3000 --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -v "$(pwd):/home/project:cached" theia-gpr:latest
```

## 4. access theia IDE using your browser and the uri http://localhost:3000

## 5. how to build this docker image
```bash
# cd to root folder of this reppo
docker build -f Dockerfile -t theia-gpr .
# or without cache
docker build --no-cache -f Dockerfile -t theia-gpr .
# run local image
docker run --init -it -p 3000:3000 -v "$(pwd):/home/project:cached" theia-gpr:latest
```

## original docker image image
```bash
wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-cpp-docker/latest.package.json
wget https://raw.githubusercontent.com/theia-ide/theia-apps/master/theia-cpp-docker/Dockerfile
```