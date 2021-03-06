%% Pulsed LIDAR simulator for MSc thesis
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PURPOSE: Write a stand-alone pulsed LIDAR simulator tool to use in the
% MSc thesis. The tool must be as generic as possible.
%
% The user inputs should be the LIDAR position, the inclination angle of
% the LIDAR (theta), the azimuthial angle (phi) over which the LIDAR will
% scan the exact location of interest, the probe length, and the range
% spacing (gap between the range gates).
%
% The output(s) should be the reconstructed velocity at that specific point
%(at least for the moment).
%
% NOTE: The scripts assumes ground based LIDARs therefore all the
% geometrical calculations are performed based on that.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Created: February 2nd, 2017
% Last edited: February 13, 2017
% Author: Nikolaos Frouzakis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% User input section %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear all
clc

%% Operational mode selection

% operational mode: 
% Select 'p' for PPI or 's' for staring mode.
operationMode = 'p';

%% Selection of weighting function shape

% choose type of weighting function:
% 't' for triangular-shaped function
% 'g' for gaussian-shaped function
weightingFuncType = 't';

%% Number of LIDARs

% choose number of LIDARs that participate in the campaign (1,2 or 3)
nLidars = 3;

%% Dummies - These variable are just for testing

% Dimensions of dummy domain. They will be erased once the real LES grid
% will be implemented
xDimension = 190;
yDimension = 250;
zDimension = 160;

% Each dimension consists of 2 points per unit length
pointsPerDimensionLength = 1;

xVector = linspace(-xDimension/2,xDimension/2,xDimension*pointsPerDimensionLength);
yVector = linspace(0,yDimension,yDimension*pointsPerDimensionLength);
zVector = linspace(0,zDimension,zDimension*pointsPerDimensionLength);


% % just for testing load the ainslie wake model
% load('wake_ainslie.mat')
% 
% wake_ainslie.x(82,:) = [];
% wake_ainslie.y(82,:) = [];
% wake_ainslie.u(82,:) = [];
% wake_ainslie.v(82,:) = [];
% 
% wake_ainslie.v = 50*wake_ainslie.v;
% 
% xVector = wake_ainslie.x(1,:);
% yVector = wake_ainslie.y(:,1)';
% zVector = linspace(0,zDimension,zDimension*pointsPerDimensionLength);

% Create dummy domain to try out the interpolation
[Domain.x, Domain.y, Domain.z] = meshgrid(xVector, yVector, zVector);

% The user is asked to insert both rotor radius in order to normalize all 
% dimensions w.r.t. that. However, the normalization is NOT implemented
% yet.

% Wind turbine rotor radius [in metres]
R = 40;

% mean wind speed (m/s)
meanWindSpeed = 12;

% create wind field with linear shear (in the x direction)
maxWindSpeed = 25;

% windmatrix = linspace(0,maxWindSpeed,length(xVector));
% windmatrix2 = repmat(windmatrix,[length(yVector) 1]);
% windmatrix3 = repmat(windmatrix2,[1 1 length(zVector)]);
% %

% create 3D grid where both u- and y- component increase with x and y
% respectively.
% [uComp,vComp,wComp] = meshgrid(ones(length(xVector),1),...
%     meanWindSpeed*ones(length(yVector),1),linspace(0,maxWindSpeed,length(zVector)));

% dummy probe length
dummylength = 20;

% dummy power law for wind speed = 12m/s at 100 metres and a = 0.3:
shearExp = 0.3;

uVerticalGrid = meanWindSpeed*(zVector/100).^shearExp;
vVerticalGrid = linspace(1,3,length(zVector));

zTrue = 3.5:5:140;

uVerticalTrue = meanWindSpeed*(zTrue/100).^shearExp;
vVerticalTrue = 1/70*zTrue + 1;

%%

% umag = 0;
vmag = 1;
wmag = 0.5;

% repmat the v-component for all y's
vmag = repmat(vVerticalGrid,length(xVector),1);
vmag = repmat(vmag,[1,1,length(yVector)]);
vmag = permute(vmag,[3 1 2]);

% repmat the vertical velocity profile for all x's:
umag = repmat(uVerticalGrid,length(xVector),1);

% repmat again for all 
umag = repmat(umag,[1,1,length(yVector)]);
umag = permute(umag,[3 1 2]);

% figure
% surf(zVector,xVector,u)
% xlabel('x axis')
% ylabel('z axis')
% colorbar

% Create dummy laminar velocity field
% uComp = meanWindSpeed*ones(size(Domain.x)) - 1.5*meanWindSpeed*rand(size(Domain.x));;
% uComp = meanWindSpeed*rand(size(Domain.x));
% uComp(:,1:length(xVector)/2,:) = 1;

uComp = umag.*ones(size(Domain.x));
vComp = vmag.*ones(size(Domain.x));
wComp = wmag.*ones(size(Domain.x));
% uComp = repmat(wake_ainslie.u,1,1,length(zVector));
% vComp = repmat(wake_ainslie.v,1,1,length(zVector));
% wComp = wmag*ones(size(Domain.x));

% the following plot causes the computer to run out of memory.
% % plot wind field
% figure
% scatter3(Domain.x(:),Domain.y(:),Domain.z(:),vComp(:))
%% Position of 1st LIDAR

% Give the lidar position (we assume that this point is the origin of the
% beam). The values should be in METRES. Put the lidar in the middle of the
% x-dimension
Lidar(1).x = 0;%xDimension/2;
Lidar(1).y = 0;
Lidar(1).z = 10;

%% Information about the probe of the 1st LIDAR

% Gap between the Lidar and the first range gate. Number in METRES
probe(1).FirstGap = 40;

% probe length in METRES
probe(1).Length = dummylength;

% points per unit length for the probe
probe(1).PointsPerLength = 1;

%% Information about additional LIDARs 

if (nLidars > 1)
    
    % position of second LIDAR in cartesian coordinates
    Lidar(2).x = xDimension/2;
    Lidar(2).y = 160;
    Lidar(2).z = 20; 

    % FirstGap, PointsPerLength and NRgates will remain the same.
    probe(2).FirstGap = probe(1).FirstGap;
    probe(2).PointsPerLength = probe(1).PointsPerLength;

    % change the probe length if needed 
    probe(2).Length = dummylength;
    
%     % RangeGateGap is again twice the Length
%     probe(2).RangeGateGap = 2*probe(2).Length;
    
    % check if there is a 3rd LIDAR and assign the ncessary values
    if nLidars == 3
        % position of 3rd LIDAR in cartesian coordinates
        Lidar(3).x = -xDimension/2;
        Lidar(3).y = yDimension;
        Lidar(3).z = 20; 

        % FirstGap, PointsPerLength and NRgates will remain the same.
        probe(3).FirstGap = probe(1).FirstGap;
        probe(3).PointsPerLength = probe(1).PointsPerLength;

        % change the probe length if needed 
        probe(3).Length = dummylength;

%         % RangeGateGap is again twice the Length
%         probe(3).RangeGateGap = 2*probe(3).Length;  
    end
end

%% 
if (operationMode == 'p')
    
    focalPoint = [0 150 30];
    % Distance between range gates (should be at least equal to the
    % probeLength). Now I put it twice the probeLength. It is subject to change
    % in the future.
    probe(1).RangeGateGap = 2*probe(1).Length;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This part was used when the input was radial distance and elevation
% angle. After the update, the input is a focal point in cartesian
% coordinates so this part is not used anymore

    % Radial distance to the point where we want to measure. The distance
    % should be larger that FirstGap + Length/2
%     probe(1).RadialDist2MeasurePoint = 57;

    % Inclination angle theta. The value must be in DEGREES. This angle also
    % corresponds to the point we want to measure.
    % WARNING: If 2 or less LIDARs are used for the measurement, the
    % inclination angle should be as small as possible to ensure small
    % contribution of the w-component in the reconstructed velocity.
    thetaLidar = nan(1,nLidars);
%     thetaLidar(1) = 30;

    % convert thetaLidar to radians
%     thetaLidar(1) = deg2rad(thetaLidar(1));

    % Here it is assumed that the LIDAR is facing directly at the point we want
    % to measure, therefore the azimuthal angle of the point of interest is 0.
%     phiMeasurePoint = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % azimuthial angle phi. The value must be in DEGREES. The lidar will scan
    % from -phi to +phi.
    phiLidar = 25;
    phiStep = 5;

    % number of range gates we want to measure.
    % NOTE: The code will return 3 range gates per Lidar UNLESS the
    % measurement point is too far from the Lidar location. If this is true
    % and more range gates fit before the one that actually contain the
    % focal point, then more range gates will be returned. If that is the
    % case then the focal point is always included in the last range gate.
    probe(1).NRangeGates = 3;
    
    % include the number of range gates in the probe(2) structure as well.
    if (nLidars > 1)
        probe(nLidars).NRangeGates = probe(1).NRangeGates;
        probe(nLidars-1).NRangeGates = probe(1).NRangeGates;
        
        % RangeGateGap is again twice the Length
        probe(nLidars).RangeGateGap = 2*probe(nLidars).Length;
        probe(nLidars-1).RangeGateGap = 2*probe(nLidars-1).Length;

    end;
    
    % call 'PPImode' script
    PPImode
else
    % matrix with the input measurement points. The matrix is [n x 3]. 
    % Each row represents one point and each column represents the x,y,z 
    % coordinate of that point.
    
%     CartInputPoints = [60 160 0; 60 40 0; -30 200 0; -40 50 0; 30 130 0];
%     CartInputPoints = [-80 175 0; -50 145 0; 0 95 0; 50 45 0; 80 15 0];
%     CartInputPoints = [CartInputPoints zeros(size(CartInputPoints,1),1)];
%     CartInputPoints = [repmat([50 80],length(zTrue),1) zTrue'];
%     CartInputPoints = [50 -50 20; 50 0 20; 50 50 20; 0 50 20; -50 50 20; -50 0 20; -50 -50 20; 0 -50 20];
%     CartInputPoints = [repmat([50 80],length(zVector(6:10:end-6)),1) zVector(6:10:end-6)'];%; repmat([-50 150],10,1) linspace(1,zDimension-10,10)'];
%     CartInputPoints = [xVector(8:10:end-5)' repmat([79 89],length(xVector(8:10:end-5)),1)];
%     CartInputPoints = [xVector(10:10:end-5)' repmat([yVector(80) zVector(51)],length(xVector(10:10:end-5)),1)];
%     CartInputPoints = [linspace(224,974,31)' -4*ones(31,1) 50*ones(31,1)];
%         CartInputPoints = [(-87.5)' repmat([-1 50],length((220:25:970)),1)];
    CartInputPoints = [0 150 20];
    % call 'StaringMode' script
    StaringMode
end     

%%
% 
% figure
% quiver3(Domain.x,Domain.y,Domain.z,uComp,vComp,wComp,0.2)
% axis([-1 6 4 7 0 zDimension])
% view([70 50])
% xlabel('x dimension')
% ylabel('y dimension')
% zlabel('Height')


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% End of User Input %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% DONT CHANGE ANYTHING BELOW THIS LINE %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% call printLidarInfo script to display all the user choices
printLidarInfo


% domain2.x = xVector; domain2.y = yVector; domain2.z = zVector;
% 
% % preallocate cell array
% domain{length(xVector),length(yVector),length(zVector)} = [];
% for xx = 1:length(xVector)
%     for yy = 1:length(yVector)
%         for zz = 1:length(zVector)
%             domain{xx,yy,zz} = {[xVector(xx),yVector(yy),zVector(zz)]};
%         end
%     end
% end
% clear xx yy zz

% Example: how to access the y-coordinate of the grid point (10,42,14):
% domain{10,42,14}{1}(2)
%
% Instead of the for loops you can also do domain = {xVector,yVector,zVector};
% but then you access the same y-coordinate: 
% domain2{2}(42)
% Create u,v and w components of the wind. For each meter of the x,y,z
% dimensions, there are 2 points (so 1 point every 0.5 metres).


