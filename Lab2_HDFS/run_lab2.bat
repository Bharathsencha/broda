@echo off
setlocal
title BDA Lab 2 - HDFS

echo ==========================================
echo           BDA Lab 2 - HDFS
echo ==========================================
echo.

docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or Docker is not running.
    pause
    exit /b 1
)

echo [1/10] Checking Java-enabled Hadoop image...
docker image inspect apache/hadoop:withjava >nul 2>&1
if errorlevel 1 (
    echo Creating Java-enabled image from the Lab 1 container...
    docker ps -a --format "{{.Names}}" | findstr /x "hadoop" >nul
    if errorlevel 1 (
        echo ERROR: Lab 1 container 'hadoop' was not found.
        echo Run Lab 1 once first so Java can be installed.
        pause
        exit /b 1
    )
    docker start hadoop >nul 2>&1
    docker exec hadoop javac -version
    docker commit hadoop apache/hadoop:withjava
    if errorlevel 1 (
        echo ERROR: Could not create apache/hadoop:withjava.
        pause
        exit /b 1
    )
)

echo.
echo [2/10] Starting HDFS cluster...
docker compose up -d
if errorlevel 1 (
    echo ERROR: Could not start HDFS.
    pause
    exit /b 1
)

echo.
echo [3/10] Waiting for NameNode and DataNode...
timeout /t 15 /nobreak >nul
docker compose ps

echo.
echo [4/10] Creating HDFS directory...
docker compose exec namenode bash -c "hdfs dfs -mkdir -p /user/student"
if errorlevel 1 (
    echo ERROR: Could not create HDFS directory.
    pause
    exit /b 1
)

echo.
echo [5/10] Copying HdfsDemo.java...
docker compose cp HdfsDemo.java namenode:/opt/hadoop/HdfsDemo.java
if errorlevel 1 (
    echo ERROR: Could not copy HdfsDemo.java.
    pause
    exit /b 1
)

echo.
echo [6/10] Compiling...
docker compose exec namenode bash -c "cd /opt/hadoop && rm -rf classes hdfsdemo.jar && export HADOOP_CLASSPATH=\$(hadoop classpath) && mkdir classes && javac -classpath \$HADOOP_CLASSPATH -d classes HdfsDemo.java"
if errorlevel 1 (
    echo ERROR: Compilation failed.
    pause
    exit /b 1
)

echo.
echo [7/10] Creating JAR...
docker compose exec namenode bash -c "cd /opt/hadoop && jar -cvf hdfsdemo.jar -C classes ."
if errorlevel 1 (
    echo ERROR: JAR creation failed.
    pause
    exit /b 1
)

echo.
echo [8/10] Running HDFS Java program...
docker compose exec namenode bash -c "cd /opt/hadoop && hadoop jar hdfsdemo.jar HdfsDemo"
if errorlevel 1 (
    echo ERROR: Program failed.
    pause
    exit /b 1
)

echo.
echo [9/10] Verifying file on HDFS...
docker compose exec namenode bash -c "hdfs dfs -cat /user/student/quangle.txt"

echo.
echo ==========================================
echo Lab 2 completed successfully.
echo ==========================================
echo HDFS Web UI: http://localhost:9870
echo.
pause
endlocal
