%  --------------------------------------------------------
%  Online-Object-Detection Demo
%  Author: Elisa Maiettini
%  --------------------------------------------------------

% Yarp imports
yarp.matlab.LoadYarp

import yarp.BufferedPortImageRgb
import yarp.RpcServer
import yarp.BufferedPortBottle
import yarp.Port
import yarp.Bottle
import yarp.ImageRgb
import yarp.Image
import yarp.PixelRgb

%Ports definition
portCmd                 = yarp.BufferedPortBottle;        % Port for reading commands
portImage               = yarp.BufferedPortImageRgb;      % Buffered Port for reading image
portAnnotation          = yarp.BufferedPortBottle;        % Port for receiving annotations
portDets                = yarp.BufferedPortBottle;        % Port for sending detections
portImg                 = yarp.Port;                      % Port for propagating images
portRegs                = yarp.BufferedPortBottle;        % Port for sending detections
portRefineAnnotationIN  = yarp.BufferedPortBottle;
portRefineImageOUT      = yarp.Port;                      % Port for propagating images
portRefineAnnotationOUT = yarp.BufferedPortBottle;        % Port for sending detections
% portRefineImageIN      = yarp.BufferedPortImageRgb;      % Buffered Port for reading image

%first close the port just in case (this is to try to prevent matlab from beuing unresponsive)
portCmd.close;
portImage.close;
portAnnotation.close;
portDets.close;
portImg.close;
portRegs.close;
portRefineAnnotationIN.close;
portRefineImageOUT.close;
portRefineAnnotationOUT.close;

% Open ports 
disp('Opening ports...');

portCmd.open('/detection/command:i');
disp('opened port /detection/command:i');
pause(0.5);

portImage.open('/detection/img:i');
disp('opened port /detection/img:i');
pause(0.5);

portAnnotation.open('/detection/annotations:i');
disp('opened port /detection/annotations:i');
pause(0.5);

% portRefineImageIN.open('/detection/refine/img:i');
% disp('opened port /detection/refine/img:i');
% pause(0.5);

portRefineAnnotationIN.open('/detection/refine/annotations:i');
disp('opened port /detection/refine/annotations:i');
pause(0.5);

portRefineImageOUT.open('/detection/refine/image:o');
disp('opened port /detection/refine/image:o');
pause(0.5);

portRefineAnnotationOUT.open('/detection/refine/predictions:o');
disp('opened port /detection/refine/predictions:o');
pause(0.5);

portDets.open('/detection/dets:o');
disp('opened port /detection/dets:o');
pause(0.5);

portImg.open('/detection/img:o');
disp('opened port /detection/img:o');
pause(0.5);

portRegs.open('/detection/regions:o');
disp('opened port /detection/regions:o');
pause(0.5);

% portRefine.open('/detection/cmdrefine:o');
% disp('opened port /detection/cmdrefine:o');
% pause(0.5);

% Images options
% h       = 240;
% w       = 320;
h       = 480;
w       = 640;
pixSize = 3;
tool    = yarp.matlab.YarpImageHelper(h, w);

disp('yarp initialization done.');

