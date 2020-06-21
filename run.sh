docker stop percy
docker rm percy
docker run -tid -p 8080:80 --name percy budal/hello /script/run.sh
