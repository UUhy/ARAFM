classdef ARAFM
    
    properties(GetAccess=public, SetAccess=protected, Hidden=false)
        
        %Pixel scaling in nm/pixel
        %scale  :   double      :   [scaleX scaleY scaleZ]
        scale;
        
        %Image size
        %size   :   integers    :   [rows columns]
        dim;
        
        %Images
        %data   :   NxMxI array :   Dataset of images
        %       :   I           :   Number of images stored in file
        %                       :   Index corresponds to order of image
        %                           saved
        %       :   NxM         :   Dimensions of image
        %Need to figure out the orientation of images stored so that
        %   we can automatically configure the orientation of the image as
        %   we load it
        data;
        
        %Scan Rate
        %scanRate   :   float   :   scan rate in [Hz]
        scanRate;
            
        %Scan Angle
        %scanRate   :   float   :   scan angle in [degree]
        scanAngle;
        
        %InvOLS
        invOLS;
            
        %AmpInvOLS
        ampInvOLS;
        
        %Spring Constant
        springConstant;
        
        %Amplitude of force curve
        %amplitude  :   Nx1 array   :   Amplitude of AC oscillation in [m]
        %                           :   or Amplitdue of deflection [m]
        amplitude;
        
        %zSensor    :   Nx1 array   :   Position of Z piezo in [m]
        zsensor;
    end
    
    properties(GetAccess=public, SetAccess=protected, Hidden=true)
        %No Private Variables
    end
    
    properties(GetAccess=private, Constant=true, Hidden=true)
        %No Constants
    end
    
    methods (Access=public, Sealed=true)
        
        function obj = ARAFM()
        %obj = ARAFM()
        %
        %   Output:
        %       obj     	:   ARAFM instance
        %
        %   Description:
        %   Constructor for ARAFM class.  A constructor initializes all
        %   the variables in the class.
        %
        %   See also loadData, imageData
     
            obj.scale = [1 1 1];
            obj.dim = [128 128];
            obj.data = [];
        end
        
        function obj = load(obj, filename)
        %obj = load(filename)
        %
        %   Output:
        %       obj     	:   ARAFM instance
        %
        %   Input:
        %       filename    :   string  =   name of file with AR AFM data
        %
        %   Description:
        %   Loads AFM data.
        %
        %   See also load, loadForce, showImage, showForce
            tmp = IBWread(filename);
            obj.scale = tmp.dx;
            obj.dim = size(tmp.y);
            obj.data = tmp.y;
            
            %Determine the position of notes
            x = split(tmp.WaveNotes);
            %for i = 1:length(x)
            %    disp(strcat(num2str(i),'_________',x(i)));
            %end
            
            obj.scanRate = str2double(x(8));                %[Hz]
            obj.scanAngle = str2double(x(20));              %[degree]
            obj.invOLS = str2double(x(24));                 %[nm/V]?????
            obj.ampInvOLS = str2double(x(28));              %[nm/V]
            obj.springConstant = str2double(x(26));         %[N/m]
        end
        
        function obj = loadForce(obj, filename)
        %obj = loadForce(filename)
        %
        %   Output:
        %       obj     	:   ARAFM instance
        %
        %   Input:
        %       filename    :   string  =   name of file with AR force data
        %
        %   Description:
        %   Loads single force data
        %
        %   See also load, loadForce, showImage, showForce
            tmp = IBWread(filename);
            obj.zsensor = tmp.y(:,1);
            obj.amplitude = tmp.y(:,2);
        end
        
        function obj = showImage(obj)
        %obj = showImage()
        %
        %   Output:
        %       obj     	:   ARAFM instance
        %
        %   Description:
        %   Show the first Image from the dataset
        %
        %   See also load, loadForce, showImage, showForce
            colormap(gray);
            x = (1:obj.dim(2))*obj.scale(1)*1e6;
            y = (1:obj.dim(1))*obj.scale(2)*1e6;
            surf(x,y,obj.data(:,:,1),'LineStyle','none');
            view(2);
            axis square tight
            xlabel('X [um]');
            ylabel('Y [um]');
        end
        
        function [zGap, zEnd, zStart] = showForce(obj, varargin)
        %obj = showImage()
        %
        %   Output:
        %       zGap     	:   Estimated gap between tip and sample
        %                       surface at end of force measurement
        %       zEnd        :   Z sensor reading at end of measurement
        %   
        %   Input:
        %       *display    :   boolean     :   display the plot?
        %                   :   default     :   true
        %
        %   Description:
        %   Show the force curve
        %
        %   See also load, loadForce, showImage, showForce
            display = true;
            if nargin > 1
                display = false;
            end
        
            triggerIndex = find(obj.amplitude == min(obj.amplitude));
            nAverage = 20;
            triggerOffset = 10;
            y = obj.amplitude(1:triggerIndex-triggerOffset);
            tmp = abs(diff(smooth(diff(smooth(y,nAverage)),nAverage)));
            tmp = tmp(2:end-1);
            extKnee = find(tmp == max(tmp)) + 1;
            y = obj.amplitude(triggerIndex+triggerOffset:end);
            tmp = abs(diff(smooth(diff(smooth(y,nAverage)),nAverage)));
            tmp = tmp(2:end-1);
            retKnee = find(tmp == max(tmp)) + 1 + triggerOffset + triggerIndex;
            zGap = round(abs(obj.zsensor(end)-obj.zsensor(retKnee))*1e9);
            zEnd = obj.zsensor(end)*1e9;
            zStart = obj.zsensor(1)*1e9;
            
            if display
                figure;
                hold on
                plot(obj.zsensor(1:triggerIndex)*1e9, ...
                    obj.amplitude(1:triggerIndex)*1e9, ...
                    'r','LineWidth',7);
                plot(obj.zsensor(triggerIndex+1:end)*1e9, ...
                    obj.amplitude(triggerIndex+1:end)*1e9,'b');
                plot(obj.zsensor(extKnee)*1e9,obj.amplitude(extKnee)*1e9,'go');
                plot(obj.zsensor(retKnee)*1e9,obj.amplitude(retKnee)*1e9,'mo');
                hold off
                set(gca,'xdir','reverse') 
                xlabel('Z Sensor [nm]');
                ylabel('Amplitude [nm]');
                legend('Extend','Retract','Extend Knee', ...
                    strcat('Z Gap = ',num2str(zGap),' [nm]'),'location','se');
            end
        end
    end
end