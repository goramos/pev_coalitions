# distribution extension (version 6.1)

This folder contains the source files of the `distribution` extension, used by all algorithms of the `pev_coalitions` project to compute the characteristic function of the coalitions. The present source files are compatible with NetLogo 6.1.1 (see not below).

:::warning
Important! The present instructions are compatible with NetLogo 6.1.1 (and, consequently, Java 8) and were tested on Mac OS X 10.15 and Ubuntu 18.04. Observe that this version of NetLogo is only compatible with Java 8, which is required to recompile the sources (see step 3 below). 
:::

## Instructions to recompile the sources and generate the jar file

1. Open command line and access this directory.

2. Copy NetLogo's jar files directory to the current directory. 
    ```bash
    cp -r <NetLogo_path>/Java/ ./NetLogoJars
    ```
    (Note: in NetLogo 6.1.1, the jar files are located in `NetLogo 6.1.1/Java`)

3. Compile the source files.
    ```bash
    javac -classpath "NetLogoJars/netlogo-6.1.1.jar" -d classes src/distribution/V2G.java src/distribution/Similarity.java src/distribution/DistributionManager.java
    ```
    (Note: the above command assumes that folder `classes` already exists)

4. Create the jar file.
    ```bash
    jar cvfm distribution/distribution.jar manifest.txt -C classes .
    ```
    (Note: the above command assumes that folder `distribution` already exists)

5. Now, in order to use the extension, you just need to copy the `distribution` folder to the same directory as the model that will use the extension.