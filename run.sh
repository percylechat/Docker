docker stop percy
docker rm percy
docker run -tid -p 80:80 --name percy budal/hello /script/run.sh
