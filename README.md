# WS_demo

This repository contains the code for the **Active Learning part** of the work described in the paper ["A Weakly Supervised Strategy for Learning Object Detection on a Humanoid Robot"](https://ieeexplore.ieee.org/stamp/stamp.jsp?arnumber=9035067). 

The diagram of the final application is as follows:
![image](https://user-images.githubusercontent.com/3706242/79279154-afacc980-7ead-11ea-8086-66aed1ed2691.jpg)

## Dependencies
- Tested Cuda versions: 9.0, 10.0
- Yarp
- Tested with Python 3.5

### For the tracker
- **numpy** (tested version: 1.13.1) e.g. `python3.5 -m pip install numpy==1.13.1`
- **opencv-python** (tested version: 3.3.0.10) e.g. `python3.5 -m pip install opencv-python==3.3.0.10`
- **tensorflow-gpu** (tested versions: 1.5.0 for Cuda 9.0 and 1.13.1 for Cuda 10.0) e.g. `python3.5 -m pip install opencv-python==1.5.0`

Then follow the installation and setup instructions reported at this [link](https://github.com/danielgordon10/re3-tensorflow), cloning the repository in the `external` folder.

## Installation
```
git clone https://github.com/Arya07/WS_demo.git
cd WS_demo
mkdir build
ccmake ../
make 
make install
```
