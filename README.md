# PALM-Docker

PALM-Docker allows the use of PALM within a container. This docker image contains PALM and it's dependencies 
(FSL and MATLAB). Note that PALM can be run with OCTAVE, the free alternative to MATLAB. However, the developers state
that MATLAB has faster pemutations, "Octave loads faster but it's a bit slower to run. Matlab loads very slowly, but 
then runs faster." [[1]](https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;2b797b1d.1611). Official PALM documentation
can be found [here](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/PALM)

The docker image uses the following software versions:
- PALM = downloaded from latest GitHub repository on 2020/09/07
- FSL = v6.0.3
- Matlab Compiler Runtime (MCR) = v2018b

---

## How to Run a Container

1. Pull docker image from container registry
   - ```docker pull aevia/palm:1.0```
2. Organize PALM input (images, design matrix, contrast, etc.) into one folder and note the absolute path of this folder
(/abs/path/to/palm/input/folder/)
3. Execute docker command with the PALM input folder mounted and desired PALM options:
    - ```docker run -v /abs/path/to/palm/input/folder/:/input -it aevia/palm:1.0 <palm options>```
    - PALM input folder must be mounted to /input in container
    - Help on the PALM options can be found by executing the docker command without any PALM options:
        - ```docker run -it aevia/palm:1.0```
        - For advanced options: ```docker run -it aevia/palm:1.0 -advanced```
4. Once PALM is finished, output can be found in the PALM input folder

---

## How to Build the Docker Image

IMPORTANT: Users building this docker image from scratch need MATLAB Compiler Toolbox.

There are two steps in building the docker image from scratch:
1. Create MATLAB application of PALM
2. Package the MATLAB application of PALM and it's dependencies into a docker image

To build the docker image, the user must first create a MATLAB compiled application of PALM. This requires the MATLAB
Compiler Toolbox. The version of MCR inside the docker image must match the user's MATLAB version.

### To compile a MATLAB application of PALM:
1. Download latest version of PALM code from [GitHub repository](https://github.com/andersonwinkler/PALM)
2. Open MATLAB
3. Modify your startup.m file to exclude addpath during application deployment:
    - Open your startup.m file (locate with the cmd: "which startup")
    - Add the following if statement to the startup file:
        ``` 
        if ~isdeployed
            ...
            <Existing code>
            ...
        end
4. Within the PALM code, comment out instances of the addpath command:
    - palm_checkprogs.m = lines 45 and 54
    - palm.m = line 29
5. Run the Application Compiler under APPS
6. Select palm.m as the main file
7. Under the section "Files required for your application to run", add the palm_version.txt file and fileio folder 
    (located in the downloaded PALM folder), and all of the .m files inside the repository folder 'mcr/matlab'
   - The mcr/matlab .m files were copied from fsl-6.0.3/etc/matlab
   - The .m files may need to be updated as newer versions of FSL are released.
8. Ensure that "Runtime downloaded from web" is selected
9. Click Package button
10. The compiler will return a warning about possibly missing packaged files. This warning can be safely ignored.
11. Delete the for_testing and for_redistribution folders to save space

### To package PALM in a docker image:
The following steps describe the procedure in constructing the commands within build script, 
[for_build/build_docker.sh](for_build/build_docker.sh):

1. Identify the latest version of neurodocker (at the time (ATT): 0.7.0)
2. Setup the neurodocker build string:
    1. Choose a base OS compatible with FSL (chose ubuntu:16.04)
        - ```-b ubuntu:16.04 -p apt```
    2. Choose a version of FSL (latest ATT: 6.0.3)
        - ```--fsl version=6.0.3```
    3. Choose the version of Matlab Compiler Runtime that matches the MATLAB version that compiled PALM (v2018b)
        - ```--matlabmcr version=2018b```
    4. Modify entrypoint file for easier use of PALM:
        - ```--add-to-entrypoint "[ -d /input ] && cd /input"``` 
            - This code forces the container to change the current directory to /input, which will make it easier to 
            write the PALM commands. Without this, PALM options that refer to a file will need to be prepended with 
            /input.
        - ```--add-to-entrypoint '/opt/palm-mcr/palm/for_redistribution_files_only/run_palm.sh /opt/matlabmcr-2018b/v95/ $@' ```
            - This code sets up the PALM MCR command. The user will no longer need to include the path to the MCR folder
            inside the container.
        - ```--run "sed -i '\$d' \$ND_ENTRYPOINT"```
            - Remove the last line from the startup.sh file. Without this, the docker container will continue to run 
            when no PALM options are given. The default behavior of neurodocker containers is to execute /bin/bash when 
            no arguments are given to the docker run command.
    5. Copy the MATLAB compiled PALM folder into the image
        - ```--copy mcr /opt/palm-mcr```
3. Run the neurodocker build command and output to Dockerfile
    - ```docker run repronim/neurodocker:0.7.0 generate docker [build string] > Dockerfile```
4. Build Docker image from resulting Dockerfile
    - ```docker build -t [image_tag] .```
5. Push Docker image to Dockerhub
    - ```docker push [image_tag]```

---

##Issues/Limitations
- PALM with MCR has not been thoroughly tested by the FSL community [[2]](https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=FSL;8abc52d5.1904).
It is possible that there may be unexpected issues. This docker image needs to be tested with other types of data, such 
as csv and surface data.