function [varargout] = statnet(net,TRAINMX,TRAINLAB,TESTMX,TESTLAB,Pfilter,HICI,LOCI,doROC)

% keyboard









%%

TRvec = net(TRAINMX);
TEvec = net(TESTMX);

% vec2ind can be used as a shortcut to get row index of max value in each column
TRclass = vec2ind(TRvec);
TEclass = vec2ind(TEvec);


TRGUESS = round(TRvec);
TEGUESS = round(TEvec);

TRCASEn = sum(TRAINLAB(1,:));
TRCTRLn = sum(TRAINLAB(2,:));
TECASEn = sum(TESTLAB(1,:));
TECTRLn = sum(TESTLAB(2,:));

disp(' ')
fprintf('%4.0f  number of training cases\n',TRCASEn)
fprintf('%4.0f  number of training ctrls\n',TRCTRLn)
fprintf('%4.0f  number of testing cases\n',TECASEn)
fprintf('%4.0f  number of testing ctrls\n',TECTRLn)
fprintf('%4.0f  number of times net guessed case on training data\n',sum(TRGUESS(1,:)))
fprintf('%4.0f  number of times net guessed ctrl on training data\n',sum(TRGUESS(2,:)))
fprintf('%4.0f  number of times net guessed case on testing data\n',sum(TEGUESS(1,:)))
fprintf('%4.0f  number of times net guessed ctrl on testing data\n',sum(TEGUESS(2,:)))
disp(' ')

% keyboard
LLO = min(TRAINLAB(:));
LHI = max(TRAINLAB(:));
LMID = (LHI - LLO)/2;

yguess = net(TRAINMX);
GLO = yguess <  LMID;
GHI = yguess >= LMID;
yguess(GLO) = rescale(yguess(GLO),LLO,LMID);
yguess(GHI) = rescale(yguess(GHI),LMID,LHI);


HITRPCTALL = mean(mean(TRAINLAB == round(yguess))) * 100;
disp(' '); disp('------------ TRAINING DATA ------------')
fprintf('%.2f  Percent correct on all training data \n',HITRPCTALL)


yi = yguess>HICI | yguess<LOCI;
yi = yi(1,:);
HITRPCT = mean(mean(  TRAINLAB(:,yi) == round(yguess(:,yi))  )) * 100;
HITRCON = (sum(yi) / numel(yi)) * 100;
fprintf('%.2f  Percent correct on high-confidence training data \n',HITRPCT)
fprintf('%.2f  Percent of training data registered high-confidence \n',HITRCON)
disp(' ');


yguess = net(TESTMX);
GLO = yguess <  LMID;
GHI = yguess >= LMID;
yguess(GLO) = rescale(yguess(GLO),LLO,LMID);
yguess(GHI) = rescale(yguess(GHI),LMID,LHI);


HITEPCTALL = mean(mean(TESTLAB == round(yguess))) * 100;
disp(' '); disp('------------- TEST DATA ---------------')
PERF.all = sprintf('%.2f  Percent correct on all hold-out test data',HITEPCTALL);
disp(PERF.all)




% keyboard

Ythresh = .5:.05:.90;

[Yconf, Yguess] = max(yguess);
Yguess = Yguess==1;
% Yconf = rescale(Yconf,.5,1);

Ylab = TESTLAB(1,:) == 1;

Yok = Ylab==Yguess;

Yj = Yconf >= (Ythresh');

P=zeros(numel(Ythresh),1);
M=zeros(numel(Ythresh),1);
for i = 1:numel(Ythresh)

   P(i) = sum(Yj(i,:)) / numel(Yguess);
   M(i) = mean(Yok(Yj(i,:)));

end
PMX = [Ythresh' P M];






HIC_TOPTHRESH = HICI;
HIC_BOTTHRESH = LOCI;

MIDC_TOPTHRESH = .70;
MIDC_BOTTHRESH = .30;





yi = yguess>MIDC_TOPTHRESH | yguess<MIDC_BOTTHRESH;
yi = yi(1,:);

MIDTEPCT = mean(mean(  TESTLAB(:,yi) == round(yguess(:,yi))  )) * 100;
MIDTEPOP = (sum(yi) / numel(yi)) * 100;

disp(' '); disp('--- MEDIUM CONFIDENCE ---')
PERF.midpct = sprintf('%.2f  Percent correct on mid-confidence hold-out test data',MIDTEPCT);
PERF.midpop = sprintf('%.2f  Percent of hold-out test data registered mid-confidence',MIDTEPOP);
disp(PERF.midpct);disp(PERF.midpop)











yi = yguess>HIC_TOPTHRESH | yguess<HIC_BOTTHRESH;
yi = yi(1,:);

HITEPCT = mean(mean(  TESTLAB(:,yi) == round(yguess(:,yi))  )) * 100;
HITEPOP = (sum(yi) / numel(yi)) * 100;

disp(' '); disp('--- HIGH CONFIDENCE ---')
PERF.hipct = sprintf('%.2f  Percent correct on high-confidence hold-out test data',HITEPCT);
PERF.hipop = sprintf('%.2f  Percent of hold-out test data registered high-confidence',HITEPOP);
disp(PERF.hipct);disp(PERF.hipop)

disp(' ');
fprintf('**high-confidence definition: %.2f > activation > %.2f \n',HIC_BOTTHRESH,HIC_TOPTHRESH)
fprintf('**medium-confidence definition: %.2f > activation > %.2f \n',MIDC_BOTTHRESH,MIDC_TOPTHRESH)
disp(' ')







%% PLOT MODEL PERFORMANCE

if doROC > 0


TRv = net(TRAINMX);
TEv = net(TESTMX);
TRWEIGHT = TRv(1,:);
TEWEIGHT = TEv(1,:);
TRLAB = TRAINLAB(1,:);
TELAB = TESTLAB(1,:);



GLO = TRWEIGHT <  LMID;
GHI = TRWEIGHT >= LMID;
TRWEIGHT(GLO) = rescale(TRWEIGHT(GLO),LLO,LMID);
TRWEIGHT(GHI) = rescale(TRWEIGHT(GHI),LMID,LHI);

GLO = TEWEIGHT <  LMID;
GHI = TEWEIGHT >= LMID;
TEWEIGHT(GLO) = rescale(TEWEIGHT(GLO),LLO,LMID);
TEWEIGHT(GHI) = rescale(TEWEIGHT(GHI),LMID,LHI);




%------------------------------------
% PLOT HISTOGRAMS AND ROC CURVE

close all;
fh1=figure('Units','normalized','OuterPosition',[.02 .08 .60 .80],'Color','w','MenuBar','none');
h1 = axes('Position',[.04 .80 .50 .18],'Color','none');
    h1.XLim = [-.5 .5]; h1.XLimMode = 'manual'; colormap(h1,lines(2)); hold on;
h2 = axes('Position',[.04 .62 .50 .12],'Color','none');
    h2.XLim = [-.5 .5]; h2.XLimMode = 'manual'; colormap(h2,lines(2)); hold on;
h3 = axes('Position',[.02 .02 .48 .42],'Color','none'); axis off; hold on;
h4 = axes('Position',[.02 .02 .48 .42],'Color','none','XDir','reverse'); axis off; hold on;
h5 = axes('Position',[.61 .04 .34 .40],'Color','none'); hold on;
h6 = axes('Position',[.06 .46 .40 .10],'Color','none'); axis off; hold on;
h7 = axes('Position',[.61 .52 .35 .45],'Color','none'); hold on;





axes(h7)
ph7 = scatter( round(PMX(:,2).*100) , round(PMX(:,3).*100), 2000 , PMX(:,1), '.');
ph7.MarkerEdgeColor = [0 0 0]; hold on;
ph7 = scatter( round(PMX(:,2).*100) , round(PMX(:,3).*100), 1200 , PMX(:,1), '.');
h7.YLim = [50 100]; h7.XLim = [0 100]; 
h7.XLabel.String = 'Pct. Population';
h7.YLabel.String = 'Pct. Correct';
cb = colorbar; cb.Label.String = 'Classifier Confidence Threshold';
cb.Label.Rotation = 270;
cb.Label.VerticalAlignment = 'bottom';
cb.Label.FontSize = 14;
% colormap(h7,autumn)
colormap(h7,parula)




%--- ADD DATA TO AXES ---
axes(h1)
ph1 = scatter( (rand(size(TRWEIGHT,2),1)-.5).*.1 ,...
            (1:size(TRWEIGHT,2)), 200 , TRLAB, '.');
colormap(h1,[1 .2 .2; 0 .7 .7])

axes(h2)
ph2 = scatter( (rand(size(TEWEIGHT,2),1)-.5).*.1 ,...
            (1:size(TEWEIGHT,2)), 200 , TELAB, '.');
colormap(h2,[1 .2 .2; 0 .7 .7])


ph1.XData = TRWEIGHT-.5;
ph2.XData = TEWEIGHT-.5;




ph1.MarkerFaceAlpha = .4;
ph2.MarkerFaceAlpha = .4;

ph1.MarkerEdgeAlpha = .4;
ph2.MarkerEdgeAlpha = .4;


% axes(h1); 
% p1=histogram(yguess(1,TESTLAB(1,:)==1),20,'BinLimits',[0 1],...
%         'EdgeColor','k','FaceColor','r'); title('CASE CONFIDENCE'); box on;
% 
% axes(h2); 
% p2=histogram(yguess(2,TESTLAB(1,:)==0),20,'BinLimits',[0 1]); 
%         title('CTRL CONFIDENCE');  box on;

axes(h3); 
p3=histogram(yguess(1,TESTLAB(1,:)==1),20,'BinLimits',[0 1], ...
        'EdgeColor','k','FaceColor','r');  box off;

axes(h4); 
p4=histogram(yguess(2,TESTLAB(1,:)==0),20,'BinLimits',[0 1], ...
        'EdgeColor','k','FaceColor',[0 .6 .7]);  box off;
        xlabel('\leftarrow CTRLS vs CASE \rightarrow');


% Add lines to histogram plots
ymax = max([h3.YLim,h4.YLim]);
% h1.YLim = [0 ymax];
% h2.YLim = [0 ymax];
h3.YLim = [0 ymax];
h4.YLim = [0 ymax];

% axes(h1); line([HICI HICI],[0 ymax],'Color','k','LineWidth',1,'LineStyle','--')
% axes(h1); line([LOCI LOCI],[0 ymax],'Color','k','LineWidth',1,'LineStyle','--')
% axes(h2); line([HICI HICI],[0 ymax],'Color','k','LineWidth',1,'LineStyle','--')
% axes(h2); line([LOCI LOCI],[0 ymax],'Color','k','LineWidth',1,'LineStyle','--')
axes(h4); line([.5 .5],[0 ymax],'Color','k','LineWidth',1,'LineStyle','--')


% Add summary stats to figure
axes(h6); plot(1,1)
PERF.pvn = ['P(' num2str(Pfilter) ')=' num2str(size(TRAINMX,1)) ' variants'];
text(0,2.0, PERF.pvn,'FontSize',12); 
text(0,1.5, PERF.all,'FontSize',12); 
text(0,1.0, PERF.hipct,'FontSize',12); 
text(0,0.5, PERF.hipop,'FontSize',12)

%PERF.mix = sprintf('%.0f%% scrambled training data ',MIXRATIO*100);
%text(1.5,2.0, PERF.mix,'FontSize',12)




% Add colored patch overlay to combined histogram
axes(h3);
x1 = [LOCI LOCI HICI HICI];
y1 = [0 ymax/1 ymax/1 0];
x2 = [0 0 LOCI LOCI];
y2 = [0 ymax/1 ymax/1 0];
x3 = [HICI HICI 1 1];
y3 = [0 ymax/1 ymax/1 0];
patch(x1,y1,'black','FaceAlpha',.1);
patch(x2,y2,'green','FaceAlpha',.1);
patch(x3,y3,'red','FaceAlpha',.1);


% PLOT ROC CURVE
simTRAIN = sim(net,TRAINMX);
simTEST = sim(net,TESTMX);




[TPR,FPR,THR] = roc(TRAINLAB,simTRAIN);
if size(TPR{1},2) == size(TPR{2},2)
    TPR = cell2mat(TPR');
    FPR = cell2mat(FPR');
    THR = cell2mat(THR');

    axes(h5)
    ph1 = plot(FPR',TPR','LineWidth',5,'Color',[.8 .1 .1]);
    ph2 = line([0 1],[0 1],'Color','k','LineStyle','--','LineWidth',1);
    box on; grid on
    ph1(1).Color = [.8 .1 .1];
    ph1(2).Color = [.1 .6 .7];
    

else
    TP = TPR{1}';
    FP = FPR{1}';
    TH = THR{1}';

    axes(h5)
    ph1 = plot(FP',TP','LineWidth',5,'Color',[.8 .1 .1]);
    ph2 = line([0 1],[0 1],'Color','k','LineStyle','--','LineWidth',1);
    box on; grid on; hold on

    TP = TPR{2}';
    FP = FPR{2}';
    TH = THR{2}';

    plot(FP',TP','LineWidth',5,'Color',[.1 .6 .7]);
    line([0 1],[0 1],'Color','k','LineStyle','--','LineWidth',1);
    box on; grid on


end


% END IF doROC
end






%%
NNPERF = [HITRPCTALL,HITEPCTALL,...
          MIDTEPCT,MIDTEPOP,...
          HITEPCT,HITEPOP];



if nargout>0
    varargout = {NNPERF, PMX};
end

end


%% DEEP LEARNING: CONVOLUTIONAL NEURAL NETWORK
%{
clc
clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID CASEMX CTRLMX...
COHORTS AMX AMXCASE AMXCTRL ADNN caMX coMX Pfilter...
TRAINX TRAINL TESTX TESTL TRAINMX TRAINLAB TESTMX TESTLAB net

load lettersTrainSet

TRAINMX  = TRAINX';
TRAINLAB = TRAINL';

TESTMX  = TESTX';
TESTLAB = TESTL';


[TTACTUAL,~,~] = find(TRAINLAB);
zTRAINLAB = categorical(TTACTUAL);


zTRAINMX = TRAINMX;
sz = size(zTRAINMX,1);
re = sz-1800;
rp = randperm(sz,re);
zTRAINMX(rp,:) = [];
zTRAINMX = reshape(zTRAINMX,50,36,1,size(zTRAINMX,2));



clc
size(zTRAINMX)
size(zTRAINLAB)
size(XTrain)
size(TTrain)


layers = [imageInputLayer([50 36 1]);
          convolution2dLayer(3,3);
          reluLayer();
          maxPooling2dLayer(2,'Stride',2);
          fullyConnectedLayer(size(TRAINLAB,1));
          softmaxLayer();
          classificationLayer()];

% convolution2dLayer(5,16);
% options = trainingOptions('sgdm');

options = trainingOptions('sgdm',...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropFactor',0.2,...
    'LearnRateDropPeriod',5,...
    'MaxEpochs',20,...
    'MiniBatchSize',64,...
    'Verbose',false,...
    'Plots','training-progress',...
    'OutputFcn',@(info)stopIfAccuracyNotImp(info,3));


net = trainNetwork(zTRAINMX,zTRAINLAB,layers,options);



[TTACTUAL,~,~] = find(TESTLAB);
zTESTLAB = categorical(TTACTUAL);


zTESTMX = TESTMX;
sz = size(zTESTMX,1);
re = sz-1800;
rp = randperm(sz,re);
zTESTMX(rp,:) = [];
zTESTMX = reshape(zTESTMX,50,36,1,size(zTESTMX,2));

YTest = classify(net,zTESTMX);

accuracy = sum(YTest == zTESTLAB)/numel(zTESTLAB);

disp(accuracy)



%% DEEP LEARNING: LSTM NETWORK
%}