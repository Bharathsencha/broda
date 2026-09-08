@echo off
setlocal
title BDA Lab 1 - Hadoop WordCount

echo ==========================================
echo        BDA Lab 1 - Hadoop WordCount
echo ==========================================
echo.

docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or Docker is not running.
    echo Install/start Docker Desktop and run this file again.
    pause
    exit /b 1
)

echo [1/8] Checking Hadoop container...
docker ps -a --format "{{.Names}}" | findstr /x "hadoop" >nul
if errorlevel 1 (
    echo Creating Hadoop container...
    docker run -dit --name hadoop apache/hadoop:3.3.6 bash
) else (
    docker start hadoop >nul 2>&1
)

echo.
echo [2/8] Checking Java...
docker exec hadoop javac -version >nul 2>&1
if errorlevel 1 (
    echo Java not found. Installing Java inside the container...
    docker exec -u 0 hadoop bash -c "sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Base.repo"
    docker exec -u 0 hadoop bash -c "sed -i 's|^#baseurl=http\://mirror.centos.org|baseurl=http\://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo"
    docker exec -u 0 hadoop bash -c "yum clean all"
    docker exec -u 0 hadoop bash -c "yum install -y java-1.8.0-openjdk-devel"
    if errorlevel 1 (
        echo ERROR: Java installation failed.
        pause
        exit /b 1
    )
)

echo.
echo [3/8] Copying WordCount.java...
docker cp "%~dp0WordCount.java" hadoop:/opt/hadoop/WordCount.java
if errorlevel 1 (
    echo ERROR: Could not copy WordCount.java.
    pause
    exit /b 1
)

echo.
echo [4/8] Creating input data...
docker exec hadoop bash -c "cd /opt/hadoop && rm -rf input output classes wordcount.jar && mkdir -p input && echo 'the quick brown fox the lazy dog the fox' > input/file1.txt && echo 'a quick dog and a brown fox jumped' > input/file2.txt"

echo.
echo [5/8] Compiling...
docker exec hadoop bash -c "cd /opt/hadoop && export HADOOP_CLASSPATH=\$(hadoop classpath) && mkdir classes && javac -classpath \$HADOOP_CLASSPATH -d classes WordCount.java"
if errorlevel 1 (
    echo ERROR: Compilation failed.
    pause
    exit /b 1
)

echo.
echo [6/8] Creating JAR...
docker exec hadoop bash -c "cd /opt/hadoop && jar -cvf wordcount.jar -C classes ."
if errorlevel 1 (
    echo ERROR: JAR creation failed.
    pause
    exit /b 1
)

echo.
echo [7/8] Running Hadoop WordCount...
docker exec hadoop bash -c "cd /opt/hadoop && hadoop jar wordcount.jar WordCount input output"
if errorlevel 1 (
    echo ERROR: Hadoop job failed.
    pause
    exit /b 1
)

echo.
echo ==========================================
echo              RESULT
echo ==========================================
docker exec hadoop bash -c "cat /opt/hadoop/output/part-r-00000"

echo.
echo ==========================================
echo Lab 1 completed successfully.
echo ==========================================
pause
endlocal
