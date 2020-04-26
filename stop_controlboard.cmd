@echo off
docker-compose -f controlboard.yml down
echo controlboard container is now shut down and removed
echo.
echo You might want to shut down other running containers:
echo     list running containers: docker ps
echo     stop container:          docker stop CONTAINER_ID
echo     remove container:        docker remove CONTAINER_ID
