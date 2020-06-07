docker stop percy
docker rm percy
docker run -tid --name percy budal/hello /script/run.sh
