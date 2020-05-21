#!/bin/bash

echo  "Cloning repos..." > cognitive_docker.log
echo  "==================" >> cognitive_docker.log
sudo rm -r cognitive_temp
sudo rm -r ifrm-cognitive-model-job 
sudo rm -r cognitive-real-time 
sudo rm -r cognitive-batch-mode

git clone https://github.com/SQ-ONE/ifrm-cognitive-model-job |& tee cognitive_docker.log

if [  ! -d ifrm-cognitive-model-job ]; then
    echo "Directory not created." |& tee cognitive_docker.log
    exit 1
fi

git clone https://github.com/SQ-ONE/cognitive-real-time      |& tee cognitive_docker.log
if [[ ! -d cognitive-real-time ]]; then
    echo "Directory not created." |& tee cognitive_docker.log
    exit 1
fi

git clone https://github.com/SQ-ONE/cognitive-batch-mode     |& tee cognitive_docker.log

if [[ ! -d cognitive-batch-mode  ]]; then
    echo "Directory not created." |& tee cognitive_docker.log
    exit 1
fi

echo "" >> cognitive_docker.log
echo  "Creating Temp folders...">> cognitive_docker.log
echo  "========================">> cognitive_docker.log

mkdir cognitive_temp 

echo  "Checking out ATM/POS/ECOM branches...">> cognitive_docker.log
echo  "=====================================">> cognitive_docker.log
cd ifrm-cognitive-model-job
git checkout IFRM-456    |& tee cognitive_docker.log
cd ../cognitive-real-time
git checkout IFRM-456    |& tee cognitive_docker.log
cd ../cognitive-batch-mode
git checkout IFRM-456    |& tee cognitive_docker.log

echo  "Compiling branches and Moving files...">> cognitive_docker.log
echo  "=======================================">> cognitive_docker.log
cd ../ifrm-cognitive-model-job
mkdir ../cognitive_temp/model-job
sbt assembly |& tee cognitive_docker.log
mv ./target/scala-2.11/ifrm-cognitive-model-job-assembly-0.1.jar ../cognitive_temp/model-job

#sed -i '1!b;s/POS/ATM/' application.conf
#sed -i '1!b;s/test/ATM/' application.conf
cd ../cognitive-real-time
mkdir ../cognitive_temp/real-time
sbt docker:publishLocal |& tee cognitive_docker.log
mv ./target/docker/stage/opt ../cognitive_temp/real-time/atm 
cd ../cognitive-batch-mode
sbt docker:publishLocal |& tee cognitive_docker.log
mv ./target/docker/stage/opt ../cognitive_temp/bacth-mode/atm


sed -i '2!b;s/ATM/POS/' ./src/main/resources/application.conf
sed -i '2!b;s/ATM/POS/' ../cognitive-real-time/src/main/resources/application.conf
cd ../cognitive-real-time
mkdir ../cognitive_temp/batch-mode
sbt docker:publishLocal |& tee cognitive_docker.log
mv ./target/docker/stage/opt ../cognitive_temp/real-time/pos
cd ../cognitive-batch-mode
sbt docker:publishLocal |& tee cognitive_docker.log
mv ./target/docker/stage/opt ../cognitive_temp/bacth-mode/pos


sed -i '2!b;s/POS/ECOM/' ./src/main/resources/application.conf
sed -i '2!b;s/POS/ECOM/' ../cognitive-real-time/src/main/resources/application.conf
cd ../cognitive-real-time
sbt docker:publishLocal
mv ./target/docker/stage/opt ../cognitive_temp/real-time/ecom
cd ../cognitive-batch-mode
sbt docker:publishLocal
mv ./target/docker/stage/opt ../cognitive_temp/bacth-mode/ecom


echo  "Checking out IBMB brances...">> cognitive_docker.log
echo  "============================">> cognitive_docker.log

cd ../cognitive-real-time
git checkout IFRM-457
cd ../cognitive-batch-mode
git checkout IFRM-765

echo  "Compiling branches and Moving files...">> cognitive_docker.log
echo  "=======================================">> cognitive_docker.log
cd ../cognitive-real-time
sbt docker:publishLocal
mv ./target/docker/stage/opt ../cognitive_temp/real-time/ibmb
cd ../cognitive-batch-mode
sbt docker:publishLocal
mv ./target/docker/stage/opt ../cognitive_temp/batch-mode/ibmb



echo  "Transferring files ...">>cognitive_docker.log
echo  "=======================">> cognitive_docker.log
cd ..
cp ./cognitive-model-job/Dockerfile ./cognitive_temp/model-job/Dockerfile
cp ./cognitive-real-time/cognitive-batch-mode.sh ./cognitive_temp/batch-time/cognitive-batch-mode.sh
cp ./cognitive-bacth-mode/Dockerfile ./cognitive_temp/batch-mode/_Dockerfile
cp ./cognitive-real-time/cognitive-real-time.sh ./cognitive_temp/real-time/cognitive-real-time.sh
cp ./cognitive-bacth-mode/Dockerfile ./cognitive_temp/batch-mode/_Dockerfile

echo  "Building Dockers ...">>cognitive_docker.log
echo  "=====================">> cognitive_docker.log
cd cognitive_temp/model-job
docker build  --name cognitive-model-job .
cd ../cognitive_temp/batch-mode
docker build  --name cognitive-batch-mode .
cd ../cognitive_temp/real-time
docker build  --name cognitive-real-time .

echo  "Exporting Dockers ...">>cognitive_docker.log
echo  "======================">> cognitive_docker.log
cd ..
docker save cognitive-model-job:latest | gzip > cognitive-model-job.tar.gz
docker save cognitive-batch-mode:latest | gzip > cognitive-batch-mode.tar.gz
docker save cognitive-real-time:latest | gzip > cognitive-real-time.tar.gz

echo  "Cleaning Up ...">>cognitive_docker.log
echo  "=======================">> cognitive_docker.log
sudo rm -r cognitive_temp
sudo rm -r ifrm-cognitive-model-job 
sudo rm -r cognitive-real-time 
sudo rm -r cognitive-batch-mode


echo  "Done  ...">>cognitive_docker.log
