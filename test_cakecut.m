clc;clear
%% directory inputs
% directory of OMI L2 data
datadir = '/data/tempo1/Shared/OMHCHO/';

% directory for intermediate data, input to the oversampling algorthim
inputdir = '/data/tempo1/Shared/kangsun/Oversampling/RegridPixels/input/';

% directory for output from oversampling
outputdir = '/data/tempo1/Shared/kangsun/Oversampling/RegridPixels/output/';

% dirctory containing RegridPixels.x
rundir = '/data/tempo1/Shared/kangsun/Oversampling/RegridPixels/';

% directory for plot
plotdir = '/data/tempo1/Shared/kangsun/Oversampling/RegridPixels/plot/';

addpath('/home/kangsun/matlab functions/export_fig/')
addpath('/home/kangsun/matlab functions/')
%% parameter inputs
% begin and start dates
% Startdate = [2005 3 1;
%     2006 3 1;
%     2007 3 1;
%     2008 3 1];
% 
% Enddate = [2005 5 31;
%     2006 5 31;
%     2007 5 31;
%     2008 5 31];

Startdate = [2005 7 1];
Enddate = [2005 7 31];
% step in dates, not very useful in this project
% Step = 1;

% do you wanna use destriped OMI data?
if_destripe = true;

% lat lon box
MinLat = 38; MaxLat = 43;
MinLon = -76; MaxLon = -69;
%  MinLon = -inf; MaxLon = inf;

% max cloud fraction and SZA
MaxCF = 0.3;
MaxSZA = 60;

% xtrack position mask
usextrack = [11:50];

% Resolution of oversampled L3 data?
Res = 0.05;

% minimal number of L2 pixel per grid point?
minave = 5;
%%
disp('Reading the OMI L2 file name list ....')
fprintf('\n')
tic
if ~exist('filelist','var')
    filelist = dir(datadir);
end

if ~exist('fileday','var')
fileyear = nan(size(filelist));
filemonth = fileyear;
filedate = fileyear;
fileorbit = fileyear;
for i = 1:length(filelist)
    if length(filelist(i).name) > 10
        fileyear(i) = str2double(filelist(i).name(20:23));
        filemonth(i) = str2double(filelist(i).name(25:26));
        filedate(i) = str2double(filelist(i).name(27:28));
        fileorbit(i) = str2double(filelist(i).name(36:40));
    end
end
int = ~isnan(fileyear);
filelist = filelist(int);
fileyear = fileyear(int);
filemonth = filemonth(int);
filedate = filedate(int);
fileorbit = fileorbit(int);

fileday = datenum([fileyear filemonth filedate]);
end
tt = toc;
disp(['Took ',num2str(tt),' s'])
fprintf('\n')
%%
swathname = 'OMI Total Column Amount HCHO';

% variables to read from OMI L2 files
varname = {'AMFCloudFraction','ReferenceSectorCorrectedVerticalColumn',...
    'ColumnUncertainty','MainDataQualityFlag','PixelCornerLatitudes',...
    'PixelCornerLongitudes','AirMassFactor','AirMassFactorDiagnosticFlag'};
geovarname = {'Latitude','Longitude','TimeUTC','SolarZenithAngle',...
    'XtrackQualityFlags'};

useindex = false(size(filelist));
for iperiod = 1:size(Startdate,1)
useindex = useindex | ...
    fileday >= datenum(Startdate(iperiod,:)) & fileday <= datenum(Enddate(iperiod,:));
end

% useindex = useindex(1):Step:useindex(end);
subfilelist = filelist(useindex);
norbit = sum(useindex);
savedata = cell(norbit,1);
%%
disp('Loading and subsetting OMI L2 data in parallel...')
fprintf('\n')
tic
parfor iorbit = 1:norbit
    fn = [datadir,subfilelist(iorbit).name];
    datavar = F_read_he5(fn,swathname,varname,geovarname);
    
    xtrackmask = false(size(datavar.Latitude));
    xtrackmask(usextrack,:) = true;
    
    validmask = datavar.Latitude >= MinLat & datavar.Latitude <= MaxLat & ...
        datavar.Longitude >= MinLon & datavar.Longitude <= MaxLon & ...
        datavar.MainDataQualityFlag.data == 0 & ...
        datavar.AirMassFactorDiagnosticFlag.data >= 0 & ...
        datavar.XtrackQualityFlags == 0 & ...
        datavar.SolarZenithAngle <= MaxSZA & ...
        datavar.AMFCloudFraction.data <= MaxCF & ...
        xtrackmask;
    if sum(validmask(:)) > 0
    disp(['You have ',sprintf('%5d',sum(validmask(:))),' valid L2 pixels in orbit ',num2str(iorbit),'.']);
    end
%     if if_destripe
%         tempVCD = datavar.ColumnAmountDestriped.data(validmask);
%     else
%         tempVCD = datavar.ColumnAmount.data(validmask);
%     end
    tempVCD = datavar.ReferenceSectorCorrectedVerticalColumn.data(validmask);
    tempVCD_unc = datavar.ColumnUncertainty.data(validmask);
    tempAMF = datavar.AirMassFactor.data(validmask);
    
    Lat_lowerleft = datavar.PixelCornerLatitudes.data(1:end-1,1:end-1);
    Lat_lowerright = datavar.PixelCornerLatitudes.data(2:end,1:end-1);
    Lat_upperleft = datavar.PixelCornerLatitudes.data(1:end-1,2:end);
    Lat_upperright = datavar.PixelCornerLatitudes.data(2:end,2:end);
    
    Lon_lowerleft = datavar.PixelCornerLongitudes.data(1:end-1,1:end-1);
    Lon_lowerright = datavar.PixelCornerLongitudes.data(2:end,1:end-1);
    Lon_upperleft = datavar.PixelCornerLongitudes.data(1:end-1,2:end);
    Lon_upperright = datavar.PixelCornerLongitudes.data(2:end,2:end);
    
    tempLatC = datavar.Latitude(validmask);
    tempLonC = datavar.Longitude(validmask);
    
    tempLat_lowerleft = Lat_lowerleft(validmask);
    tempLat_lowerright = Lat_lowerright(validmask);
    tempLat_upperleft = Lat_upperleft(validmask);
    tempLat_upperright = Lat_upperright(validmask);
    
    tempLon_lowerleft = Lon_lowerleft(validmask);
    tempLon_lowerright = Lon_lowerright(validmask);
    tempLon_upperleft = Lon_upperleft(validmask);
    tempLon_upperright = Lon_upperright(validmask);
    %     % plot the corners to see if it's alright
    %     plot(tempLonC,tempLatC,'.k',tempLon_lowerleft,tempLat_lowerleft,'.'...
    %         ,tempLon_lowerright,tempLat_lowerright,'o',tempLon_upperleft,tempLat_upperleft,'v'...
    %         ,tempLon_upperright,tempLat_upperright,'*')
    tempSZA = datavar.SolarZenithAngle(validmask);
    tempCF = datavar.AMFCloudFraction.data(validmask);
    
    tempdata = [tempLat_lowerleft(:),tempLat_upperleft(:),...
        tempLat_upperright(:),tempLat_lowerright(:),tempLatC(:),...
        tempLon_lowerleft(:),tempLon_upperleft(:),...
        tempLon_upperright(:),tempLon_lowerright(:),tempLonC(:),...
        tempSZA(:),tempCF(:),tempAMF(:),tempVCD(:),tempVCD_unc(:)];
    savedata{iorbit} = single(tempdata);
    
end
tt = toc;
disp(['Took ',num2str(tt),' s'])
fprintf('\n')
%%
savedata = cell2mat(savedata);
savedata = cat(2,(1:size(savedata,1))',savedata);
input_fn = ['Lat_',num2str(MinLat),'_',num2str(MaxLat),'_Lon_',...
    num2str(MinLon),'_',num2str(MaxLon),'_Year_',num2str(Startdate(1,1)),...
    num2str(Startdate(1,2),'%02d'),'_',...
    num2str(Enddate(end,1)),num2str(Enddate(end,2),'%02d'),'.dat'];
cd(inputdir)
fid = fopen(input_fn,'w');
% print data for Lei Zhu' fortran program
fprintf(fid,['%8d',repmat('%15.6f',1,13),repmat('%15.6E',1,2),'\n'],savedata');
fclose(fid);
%%
cd /data/tempo1/Shared/kangsun/Oversampling/RegridPixels/matlab_oversampling/
np = size(savedata,1);
LAT = savedata(:,2:6);LON = savedata(:,7:11);
Lon_left = floor(min(LON(:)));
Lon_right = ceil(max(LON(:)));
Lat_low = floor(min(LAT(:)));
Lat_up = ceil(max(LAT(:)));
nrows = (Lat_up-Lat_low)/Res;
ncols = (Lon_right-Lon_left)/Res;

VCD = savedata(:,end-1);
VCD_Unc = savedata(:,end);

Pixels_count = zeros(nrows,ncols);
Sum_Above = zeros(nrows,ncols);
Sum_Below = zeros(nrows,ncols);

options = [];

options.use_SRF = true;
options.m = 4;
options.n = 2;
options.use_simplified_area = true;
options.inflate_pixel = true;
options.inflationx = 1.5;
options.inflationy = 2;
tic
parfor ip = 1:np
    Lon_r = LON(ip,1:4);
    Lat_r = LAT(ip,1:4);
    Lon_c = LON(ip,5);
    Lat_c = LAT(ip,5);
    
if ~isfield(options,'inflate_pixel')
    inflate_pixel = false;
else
    inflate_pixel = options.inflate_pixel;
end

if ~isfield(options,'use_SRF')
    use_SRF = false;
else
    use_SRF = options.use_SRF;
end

if ~isfield(options,'use_simplified_area')
    use_simplified_area = false;
else
    use_simplified_area = options.use_simplified_area;
end
pixel = [];
pixel.nv = length(Lon_r);
pixel.vList = [(Lon_r(:)-Lon_left)/Res,(Lat_r(:)-Lat_low)/Res];
pixel.center = [(Lon_c-Lon_left)/Res,(Lat_c-Lat_low)/Res];
vList = pixel.vList;

% inflate_pixel and use_SRF should be used together, but don't have to
if ~use_SRF % if not use SRF, there is no point of inflating!
    inflate_pixel = false;
end

if inflate_pixel || use_SRF
    leftpoint = mean(vList(1:2,:));
    rightpoint = mean(vList(3:4,:));
    
    uppoint = mean(vList(2:3,:));
    lowpoint = mean(vList([1 4],:));
    
    % calculate the FWHM of 2-D super gaussian SRF
    % x is the xtrack, different from the OMI pixel paper, which used y
    FWHMx = sqrt((leftpoint(1)-rightpoint(1))^2+(leftpoint(2)-rightpoint(2))^2);
    % y is the along track, different from the OMI pixel paper, which used x
    FWHMy = sqrt((uppoint(1)-lowpoint(1))^2+(uppoint(2)-lowpoint(2))^2);
    
    Angle = -atan((rightpoint(2)-leftpoint(2))/(rightpoint(1)-leftpoint(1)));
    rotation_matrix = [cos(Angle), -sin(Angle);
        sin(Angle),  cos(Angle)];
end

% m is the super gaussian exponient in x (xtrack), n is in y (along track)
if use_SRF
    if ~isfield(options,'m')
        m = 4;
    else
        m = options.m;
    end
    if ~isfield(options,'n')
        n = 2;
    else
        n = options.n;
    end
end

if inflate_pixel % if inflate the pixel, update the pixel object
    % inflation factor xtrack
    if ~isfield(options,'inflationx')
        inflationx = 1.5;
    else
        inflationx = options.inflationx;
    end
    % inflation factor along track
    if ~isfield(options,'inflationy')
        inflationy = 2;
    else
        inflationy = options.inflationy;
    end
    
    diamond_orth = (rotation_matrix*...
        [[leftpoint(1) uppoint(1) rightpoint(1) lowpoint(1)]-pixel.center(1);...
        [leftpoint(2) uppoint(2) rightpoint(2) lowpoint(2)]-pixel.center(2)]);
    
    xleft = diamond_orth(1,1)*inflationx;
    xright = diamond_orth(1,3)*inflationx;
    ytop = diamond_orth(2,2)*inflationy;
    ybottom = diamond_orth(2,4)*inflationy;
    
    vList_orth = [xleft xleft xright xright;
        ybottom ytop ytop ybottom];
    
    vList_inflate = [cos(-Angle), -sin(-Angle);
        sin(-Angle),  cos(-Angle)]*vList_orth;
    
    vList_inflate = [vList_inflate(1,:)'+pixel.center(1),vList_inflate(2,:)'+pixel.center(2)];
    pixel.vList = vList_inflate;
end
% Used for the next step
id_all = 0;
pixel_area = 0;

% Perform Horizontal cut first at the integer grid lines
[sub_pixels,n_sub_pixels] = F_HcakeCut( pixel );

% Sub_Area = zeros(size(Sum_Above));
Sub_Area = zeros(nrows,ncols);
% Then perform Vertical cut for each sub pixel obtainted
% from the Horizontal cut at the integer grid lines
for id_sub = 1: n_sub_pixels
    [final_pixels, n_final_pixels] = F_VcakeCut( sub_pixels(id_sub) );
    for id_final = 1: n_final_pixels
        id_all = id_all + 1;
        % temp_area is the area of each sub polygon, at this stage
        if use_simplified_area
            temp_area = Res^2;
        else
            [ifsquare,edges] = F_if_square(final_pixels(id_final));
            if ifsquare
                temp_area = edges(1)*edges(2)*Res^2;
            else
                temp_area = F_polyarea(final_pixels(id_final))*Res^2;
            end
        end
        row = floor(min(final_pixels(id_final).vList(1:final_pixels(id_final).nv,2))) + 1;
        col = floor(min(final_pixels(id_final).vList(1:final_pixels(id_final).nv,1))) + 1;
        
        % if necessary, update temp_area to include the weighting from SRF
        if use_SRF
            temp_area = temp_area * ...
                F_2D_SG(col,row,pixel.center(1),pixel.center(2),FWHMx,FWHMy,m,n,rotation_matrix);
        end
        pixel_area = pixel_area + temp_area;
        
        % Get the overlaped area between the pixel and each cell
        Sub_Area(row,col) = temp_area;
        
%         Pixels_count(row,col) = Pixels_count(row,col) + 1;
    end
end
% Sum weighted value and weights
% Here use temp_area/A/VCD_Unc(p) as averaging weight, meaning that
% averaging weight is assumed to be proportional to the ratio of the overlap area (temp_area) to the
% pixel size (A) and inversely proportional to the error standard deviation (VCD_Unc(p)).
% If you just want fraction of overlap area as averaging weight, use: temp_area/A
% If you just want area weighted average, use: temp_area
Sum_Above = Sum_Above+Sub_Area/pixel_area/VCD_Unc(ip)*VCD(ip);
Sum_Below = Sum_Below+Sub_Area/pixel_area/VCD_Unc(ip);

end
toc
Sum_Below(Sum_Below == 0) = nan;
Average = Sum_Above./Sum_Below;
%%
clc
count = 0;
parfor i = 1:12
    count = sum(count);
end
%%
Lat_grid = Lat_low+(1:nrows)*Res-0.5*Res;
Lon_grid = Lon_left+(1:ncols)*Res-0.5*Res;
statelist = [8, 55, 32, 24 46];
S         = shaperead('/data/tempo1/Shared/kangsun/run_WRF/shapefiles/cb_2015_us_state_500k/cb_2015_us_state_500k.shp');
% Slake     = shaperead('/data/tempo1/Shared/kangsun/run_WRF/shapefiles/ne_10m_lakes_north_america/ne_10m_lakes_north_america.shp');
if ~exist('lakelist','var')
Llake     = shaperead('/data/tempo1/Shared/kangsun/run_WRF/shapefiles/ne_10m_lakes/ne_10m_lakes.shp');
lakelist = [];
left = -82;right = -74;down = 39.5;up = 45;
for i = 1:length(Llake)
    tmp = Llake(i).BoundingBox;
    if ((tmp(1,1) > left && tmp(1,1) < right) || ...
            (tmp(2,1) > left && tmp(2,1) < right)) && ...
        ((tmp(2,1) > down && tmp(2,1) < up) || ...
            (tmp(2,2) > down && tmp(2,2) < up)) 
        lakelist = [lakelist i];
    end
end
end
% close all
figure('color','w','unit','inch','position',[0 1 10 8])
set(0,'defaultaxesfontsize',13)
% h = scatter(C(:,4),C(:,3),[],C(:,5));
plotmat = Average;

h = pcolor(Lon_grid,Lat_grid,plotmat);set(h,'edgecolor','none')
hc = colorbar;
caxis([0 2e16])
hold on
for istate = 1:length(S)
    plot(S(istate).X,S(istate).Y,'color','w')
end

for ilake = lakelist
    plot(Llake(ilake).X,Llake(ilake).Y,'color','w')
end
%%
disp('Running Lei Zhu''s pixel-regriding program ...')
fprintf('\n')
tic
output_fn = ['Res_',num2str(Res),'_Lat_',num2str(MinLat),'_',...
    num2str(MaxLat),'_Lon_',...
    num2str(MinLon),'_',num2str(MaxLon),'_Year_',num2str(Startdate(1,1)),...
    num2str(Startdate(1,2),'%02d'),'_',...
    num2str(Enddate(end,1)),num2str(Enddate(end,2),'%02d'),'.dat'];
cd(rundir)

% I know this is stupid, give me a better way

fid = fopen('run_KS.sh','w');
fprintf(fid,['set Input_Dir = "',inputdir(1:end),'"\n']);
fprintf(fid,['set Output_Dir = "',outputdir(1:end),'"\n']);

fprintf(fid,['set Res = ',num2str(Res),'\n']);

fprintf(fid,['set Input_Filename = "',input_fn,'"\n']);
fprintf(fid,['set Output_Filename = "',output_fn,'"\n']);

fprintf(fid,['./RegridPixels.x<<EOF\n',...
    '$Input_Dir\n',...
    '$Output_Dir \n',...
    '$Input_Filename\n',...
    '$Output_Filename\n',...
    '$Res\n',...
    'EOF\n',...
    'quit:\n',...
    'exit']);
fclose(fid);

unix('tcsh ./run_KS.sh');
tt = toc;
disp(['Took ',num2str(tt),' s'])
fprintf('\n')