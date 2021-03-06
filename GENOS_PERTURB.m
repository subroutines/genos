%==========================================================================
%% STEP-1: LOAD THE DATASET
%==========================================================================
close all; clear; clc; rng('shuffle');
P.home = fileparts(which('GENOS.m')); cd(P.home);
P.P1 = [P.home filesep 'genos_functions'];
P.P3 = [P.P1 filesep 'genos_main_functions'];
P.P4 = [P.home filesep 'genos_other'];
addpath(join(string(struct2cell(P)),pathsep,1))
cd(P.home); P.f = filesep;


ADSP = load('GENOSDATAFINAL.mat');


P.mainmatfile = which('GENOSDATAFINAL.mat');
disp('dataset loaded')
clearvars -except P ADSP INFO


%% SET RUN OPTIONS & PATHS FOR DATA IMPORT/EXPORT
clc; clearvars -except P ADSP INFO


P.doPRO = 1;
P.doPLO = 0;
P.doORLO = 0;
P.doORHI = 0;
P.doSYN = 0;
P.NGeneStart = 1;
P.NGeneEnd = 100;
P.NGenes = P.NGeneEnd - P.NGeneStart + 1;
P.Nloops = 10;
P.FileStart = 1;
P.Nvars = 200;
P.windowSize = 50;
P.Ndots = 5;
P.Lo2Hi = true;
P.RemoveGenesByName = false;
P.RemoveBadGenes = false;
P.f = filesep;
P.basedir = 'F:\GENOSDATA\APOE_SUBGROUPS';
P.SNPTABLE= 'F:\GENOSDATA\GENOS_TOP_PROTECTIVE_SNPs.xlsx';
P.datadumpdir = 'F:\GENOSDATA\GENOS_PERTURB\PRO';

% [22 23 24 33 34 44]
%--------------------------
% P.importdir = [P.basedir P.f 'APOE_22_23_24_33_34_44' P.f 'APOE_22_23_24_33_34_44_FISHP'];
% P.APOES = '22_23_24_33_34_44';
% INFO.APOE = [22 23 24 33 34 44];


% [22 23 24 34 44]
%--------------------------
% P.importdir = [P.basedir P.f 'APOE_22_23_24_34_44' P.f 'APOE_22_23_24_34_44_FISHP'];
% P.APOES = '22_23_24_34_44';
% INFO.APOE = [22 23 24 34 44];


% [33]
%--------------------------
% P.importdir = [P.basedir P.f 'APOE_33' P.f 'APOE_33_FISHP'];
% P.APOES = '33';
% INFO.APOE = [33];


% [34 44]
%--------------------------
P.importdir = [P.basedir P.f 'APOE_34_44' P.f 'APOE_34_44_FISHP'];
P.APOES = '34_44';
INFO.APOE = [34 44];


% [33 34]
%--------------------------
% P.importdir = [P.basedir P.f 'APOE_34_44' P.f 'APOE_34_44_FISHP'];
% P.APOES = '33_44';
% INFO.APOE = [34 44];




clearvars -except P ADSP INFO



%% VALIDATE IMPORT OPTIONS & GET PATHS TO EACH FISHP.MAT FILE

P.FILES.w = what(P.importdir);
P.Nmatfiles = numel(P.FILES.w.mat);
disp(P.FILES.w.mat); disp(P.Nmatfiles);



if P.Nloops > P.Nmatfiles
disp('ABORTING: NOT ENOUGH MAT FILES TO RUN THAT MANY LOOPS');
return; 
end



clearvars -except P ADSP INFO



%==========================================================================
%% IMPORT TOP VARIANTS FROM EXCEL SHEET
%==========================================================================
clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP

PLOops = detectImportOptions(P.SNPTABLE,'Sheet','Plo');
ORLOops = detectImportOptions(P.SNPTABLE,'Sheet','ORlo');
ORHIops = detectImportOptions(P.SNPTABLE,'Sheet','ORhi');
SYNops = detectImportOptions(P.SNPTABLE,'Sheet','Syn');

PLO  = readtable(P.SNPTABLE,PLOops,'Sheet','Plo');
ORLO = readtable(P.SNPTABLE,ORLOops,'Sheet','ORlo');
ORHI = readtable(P.SNPTABLE,ORHIops,'Sheet','ORhi');
SYN = readtable(P.SNPTABLE,SYNops,'Sheet','Syn');

PLO.CHRPOS  = uint64(PLO.CHRPOS);
ORLO.CHRPOS = uint64(ORLO.CHRPOS);
ORHI.CHRPOS = uint64(ORHI.CHRPOS);
SYN.CHRPOS = uint64(SYN.CHRPOS);


clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP PLO ORLO ORHI SYN
%% FIND LOWEST P-VALUE SNP VERSION & SET CHRPOS TO THAT VERSION
%{
clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP PLO ORLO ORHI SYNA

vi = sum(LOCI.GENE == string(SYNA.GENE)' ,2) >0;

SYN = LOCI(vi,:);

SYN = sortrows(SYN,'OKFISHP');

[C,ia,ic] = unique(SYN.GENE,'stable');
SYN = SYN(ia,:);


clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP PLO ORLO ORHI SYNA SYN
%}
%--------------------------------------------------------------------------
%%
%--------------------------------------------------------------------------

ADSP.PLO  = PLO;
ADSP.ORLO = ORLO;
ADSP.ORHI = ORHI;
ADSP.SYN  = SYN;


if P.doPLO == 1
    ADSP.SNP = PLO;
elseif P.doORLO == 1
    ADSP.SNP = ORLO;
elseif P.doORHI == 1
     ADSP.SNP = ORHI;
elseif P.doSYN == 1
     ADSP.SNP = SYN;
end

clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP PLO ORLO ORHI SYN




%==========================================================================
%%   CARBON COPY MAIN VARIABLES FROM ADSP.STRUCT
%==========================================================================
%
% After evaluating this section, each variable will be copied from the
% ADSP structural array to their own base variable. This is done so
% that (1) you can access their data directly (e.g. LOCI.GENE(1:5) instead
% of ADSP.LOCI.GENE(1:5) ) and so that (2) you can always restart fresh
% here, by running this segment of code, rather than having to import the
% data from the .mat file in the section above.

LOCI = ADSP.LOCI;
CASE = ADSP.CASE;
CTRL = ADSP.CTRL;
USNP = ADSP.USNP;
PHEN = ADSP.PHEN;


clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP
head(PHEN)
head(LOCI)




%==========================================================================
%==========================================================================
%==========================================================================
%%
%
% GET DATASET PATHS FOR MACHINE LEARNING
%
%==========================================================================
%==========================================================================
%==========================================================================
clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP


% NEURAL NETWORKS CONFUSION STATS
%----------------------------------------
LOOPDATA.TR_ALL_STATS = zeros(P.Ndots,9,P.Nloops);
LOOPDATA.HO_ALL_STATS = zeros(P.Ndots,9,P.Nloops);
LOOPDATA.TR_TOP_STATS = zeros(P.Ndots,9,P.Nloops);
LOOPDATA.HO_TOP_STATS = zeros(P.Ndots,9,P.Nloops);



% CASES NEURAL NETWORKS
%----------------------------------------
LOOPDATA.CATRMEAN = zeros(P.Ndots,P.Nloops);
LOOPDATA.CATRLOMU = zeros(P.Ndots,P.Nloops);
LOOPDATA.CATRHIMU = zeros(P.Ndots,P.Nloops);
LOOPDATA.CATRLOPO = zeros(P.Ndots,P.Nloops);
LOOPDATA.CATRHIPO = zeros(P.Ndots,P.Nloops);

LOOPDATA.CAHOMEAN = zeros(P.Ndots,P.Nloops);
LOOPDATA.CAHOLOMU = zeros(P.Ndots,P.Nloops);
LOOPDATA.CAHOHIMU = zeros(P.Ndots,P.Nloops);
LOOPDATA.CAHOLOPO = zeros(P.Ndots,P.Nloops);
LOOPDATA.CAHOHIPO = zeros(P.Ndots,P.Nloops);



% TRAINED MACHINE LEARNER
%----------------------------------------
LOOPDATA.NETQ  = cell(P.Nloops);
LOOPDATA.NETD  = cell(P.Nloops);
LOOPDATA.SVMQ = nan(50,2,P.Nloops);
LOOPDATA.SVMD = nan(50,2,P.Nloops);


% NEURAL NETWORK & CONFUSION MATRIX
%----------------------------------------
LOOPDATA.CONFU_TR = nan(4,4,P.Nloops,6);
LOOPDATA.CONFU_HO = nan(4,4,P.Nloops,6);
LOOPDATA.PERF_TR = nan(P.Nloops,6,6);
LOOPDATA.PERF_HO = nan(P.Nloops,6,6);
LOOPDATA.AREA_TR = nan(50,5,P.Nloops,6);
LOOPDATA.AREA_HO = nan(50,5,P.Nloops,6);



% TARGET GENE & CHRPOS
%----------------------------------------
LOOPDATA.GENECHRPOS = cell(P.Nloops,2,P.NGenes);









%% LOOP OVER EACH GENE-CHRPOS TO PERTURB
%##########################################################################
%
% 
%
for kk = P.NGeneStart:P.NGeneEnd
%
%
% 
%##########################################################################
close all; clc;






%% LOOP OVER EACH OF 50 UNIQUE PARTICIPANT SUBSETS
%==========================================================================
% 
% 
% 
for ij = 1:P.Nloops
% 
% 
% 
%========================================================================== 
close all; clc;
clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP LOOPDATA kk ij
fprintf('\n\n | GENE LOOP: %.0f  \n | SUBSET LOOP: %.0f \n\n',kk,ij)



    % LOAD MAT DATA CONTAINING UNIQUE PARTICIPANT SUBSET

    MATDAT = load([P.FILES.w.path filesep    P.FILES.w.mat{randi(50)}   ]);


    



    % PULL OUT VARIABLES FROM MATDAT PARTICIPANT SUBSET
    VLOCI     = MATDAT.LOCI;
    VCASE     = CASE;
    VCTRL     = CTRL;
    VUSNP     = USNP;
    VTRCASE   = MATDAT.TRCASE;
    VTRCTRL   = MATDAT.TRCTRL;
    VTECASE   = MATDAT.TECASE;
    VTECTRL   = MATDAT.TECTRL;



    % SET MAIN FISHP TO TRAINING GROUP FISHP
    VLOCI.FISHP      = VLOCI.TRFISHP;
    VLOCI.FISHOR     = VLOCI.TRFISHOR;
    VLOCI.CASEREF    = VLOCI.TRCASEREF;
    VLOCI.CASEALT    = VLOCI.TRCASEALT;
    VLOCI.CTRLREF    = VLOCI.TRCTRLREF;
    VLOCI.CTRLALT    = VLOCI.TRCTRLALT;




    %======================================================================
    % REMOVE SELECT GENES BY NAME
    %======================================================================
    %{
    if P.RemoveGenesByName
    ALZGENES = string(["APOE","TOMM40","CR1","BIN1","INPP5D","HLA-DRB1","TREM2",...
        "CD2AP","NYAP1g","EPHA1","PTK2B","CLU","SPI1h","MS4A2","PICALM","SORL1",...
        "FERMT2","SLC24A4","ABCA7","CASS4","ECHDC3","ACE","MEF2C","NME8","TYRO3"]);
    for nn = 1:numel(ALZGENES)
        x = strcmp(VLOCI.GENE,ALZGENES(nn));
        VLOCI(x,:) = [];
        VCASE(x) = [];
        VCTRL(x) = [];
        VUSNP(x) = [];
    end
    end
    if P.RemoveBadGenes
    BADGENES = string(["TYRO3","TOMM40"]);
    for nn = 1:numel(BADGENES)
        x = strcmp(VLOCI.GENE,BADGENES(nn));
        VLOCI(x,:) = [];
        VCASE(x) = [];
        VCTRL(x) = [];
        VUSNP(x) = [];
    end
    end
    VLOCI.VID  = (1:size(VLOCI,1))';
    %}
    BADGENES = string(["TYRO3","TOMM40"]);
    for nn = 1:numel(BADGENES)
        x = strcmp(VLOCI.GENE,BADGENES(nn));
        VLOCI(x,:) = [];
        VCASE(x) = [];
        VCTRL(x) = [];
        VUSNP(x) = [];
    end



    %==========================================================================
    % GET GENE-CHRLOC TO PERTURB AND ENSURE IT'S #1 AMONG SNPS
    %==========================================================================

    GENE   = ADSP.SNP.GENE{kk};
    CHRPOS = ADSP.SNP.CHRPOS(kk);

    VLOCI.TRFISHP(VLOCI.CHRPOS==CHRPOS) = 0;

    LOOPDATA.GENECHRPOS{ij,1} = GENE;
    LOOPDATA.GENECHRPOS{ij,2} = CHRPOS;




    %======================================================================
    % SORT VARIANTS BY EITHER TRFISHP|CHRPOS
    %======================================================================
    [~,j]  = sort(VLOCI.TRFISHP);
    VLOCI  = VLOCI(j,:);
    VCASE  = VCASE(j);
    VCTRL  = VCTRL(j);
    VUSNP  = VUSNP(j);


    disp(GENE);
    disp(VLOCI(1:5,1:9)); 
    pause(2);


    % Save some data for the record
    INFO.TOPLOCI{ij}   = VLOCI(1:500,:);
    INFO.PHETRCASE{ij} = VTRCASE;
    INFO.PHETRCTRL{ij} = VTRCTRL;
    INFO.PHETECASE{ij} = VTECASE;
    INFO.PHETECTRL{ij} = VTECTRL;





    %======================================================================
    %      MAKE  RECTANGLE  NEURAL NET  VARIANT MATRIX
    %======================================================================
    SNPi = 1:P.windowSize;


    % EXTRACT TOP-N NUMBER OF VARIANTS
    XLOCI  = VLOCI(SNPi,:);
    XCASE  = VCASE(SNPi);
    XCTRL  = VCTRL(SNPi);
    XUSNP  = VUSNP(SNPi);


    TRPHE = [VTRCASE; VTRCTRL];
    TEPHE = [VTECASE; VTECTRL];


    % SCRAMBLE TRAINING PHENOTYPE ORDER
    NVARS  = size(TRPHE,1);         % Total number of people
    k      = randperm(NVARS)';      % Get N random ints in range 1:N
    TRPHE  = TRPHE(k,:);            % Scramble Phenotype table

    % SCRAMBLE TESTING PHENOTYPE ORDER
    NVARS  = size(TEPHE,1);         % Total number of people
    k      = randperm(NVARS)';      % Get N random ints in range 1:N
    TEPHE  = TEPHE(k,:);            % Scramble Phenotype table



    [PVXt, VXt, DVXt, DXt, Yt, YDt] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TRPHE,[-1 -0 2 3]);
    [PVXh, VXh, DVXh, DXh, Yh, YDh] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TEPHE,[-1 -0 2 3]);




    %======================================================================
    %%       TRAIN NEURAL NETWORK CLASSIFIER
    %======================================================================
    clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP LOOPDATA kk ij...
    VLOCI VCASE VCTRL VUSNP VTRCASE VTRCTRL VTECASE VTECTRL SNPi XLOCI...
    XCASE XCTRL XUSNP TRPHE TEPHE PVXt DVXt PVXh DVXh VXt VXh Yt Yh...
    YDt YDh DXt DXh netq netd net 
    %----------------------------------------------------------------------

    % SET NEURAL NET PARAMETERS
    NN = patternnet([50 20],'trainscg','crossentropy');
    NN.trainParam.max_fail = 50;
    NN.trainParam.showWindow = 0;
    NN.performParam.regularization = 0.1;
    NN.performParam.normalization = 'none';



    netq = train(NN,VXt',Yt');  % TRAIN NETQ
    [ERR,~,~,~] = confusion(Yh',netq(VXh'));
    qCOR = 1-ERR;
    LOOPDATA.NETQ(ij) = {netq};
    maxq = qCOR;
    


    for nn = 1:5
    
        netq = train(NN,VXt',Yt');  % TRAIN NETQ

        [ERR,~,~,~] = confusion(Yh',netq(VXh'));
        qCOR = 1-ERR;

        if qCOR>maxq
            LOOPDATA.NETQ(ij) = {netq};
            maxq = qCOR;
        end
        fprintf('\n NN-LOOP: %.0f  \n PCT-CORRECT: %.1f \n\n', nn, maxq*100);
    end


    fprintf('\n maxq: %0.4f \n',  maxq)

    net = LOOPDATA.NETQ{ij};

    [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', net(VXt'));
    [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', net(VXh'));

    LOOPDATA.CONFU_TR(:,:,ij, 1) = CONFU_TR;
    LOOPDATA.CONFU_HO(:,:,ij, 1) = CONFU_HO;
    LOOPDATA.PERF_TR(ij,:,    1) = PERF_TR;
    LOOPDATA.PERF_HO(ij,:,    1) = PERF_HO;
    LOOPDATA.AREA_TR(:,:,ij,  1) = AREA_TR;
    LOOPDATA.AREA_HO(:,:,ij,  1) = AREA_HO;





% MAKE TWO NEURAL NET ARCHITECTURES COMPETE
%----------------------------------------------------------------------
%{
    maxq=0;
    maxd=0;

    for nn = 1:5
        disp(nn)
    
        netq = train(NN,VXt',Yt');  % TRAIN NETQ
        netd = train(NN,DXt',Yt');  % TRAIN NETD



        [ERR,~,~,~] = confusion(Yh',netq(VXh'));
        qCOR = 1-ERR;
        [ERR,~,~,~] = confusion(Yh',netd(DXh'));
        dCOR = 1-ERR;

        if qCOR>maxq
            LOOPDATA.NETQ(ij) = {netq};
            maxq = qCOR;
        end
        if dCOR>maxd
            LOOPDATA.NETD(ij) = {netd};
            maxd = dCOR;
        end
    fprintf('\n maxq: %0.4f ',  maxq)
    fprintf('\n maxd: %0.4f \n',maxd)
    end



    netq = LOOPDATA.NETQ{ij};
    netd = LOOPDATA.NETD{ij};


    % if maxq > maxd
    %     net = netq;
    %     [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', netq(VXt'),1);
    %     [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', netq(VXh'),1);
    % else
    %     net = netd;
    %     [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', netd(DXt'),1);
    %     [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', netd(DXh'),1);
    % end

%}
%----------------------------------------------------------------------






%% SYSTEMATICALLY PERTURB NEURAL NET BY ALTERING (1) SNP IN ALL PARTICIPANTS
clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP LOOPDATA kk ij...
VLOCI VCASE VCTRL VUSNP VTRCASE VTRCTRL VTECASE VTECTRL SNPi XLOCI...
XCASE XCTRL XUSNP TRPHE TEPHE PVXt DVXt PVXh DVXh VXt VXh Yt Yh...
YDt YDh DXt DXh netq netd net 
%----------------------------------------------------------------------


    GENE   = ADSP.SNP.GENE{kk};
    CHRPOS = ADSP.SNP.CHRPOS(kk);



    %------------------------------------------------------------------
    % TRAINING APOE:  22 23 24 33 34 44
    % HOLDOUT  APOE:  33
    % HOLDOUT  VARS:  5
    %------------------------------------------------------------------
    [PVXt, VXt, DVXt, DXt, Yt, YDt] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TRPHE,[-1 -0 2 3]);
    [PVXh, VXh, DVXh, DXh, Yh, YDh] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TEPHE,[-1 -0 2 3]);


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE APOE33 ALLELE
    e4i = find(XLOCI.CHRPOS==190045411941);
    PVXh(:,(9+e4i)) = -1;
    VXh(:,e4i)      = -1;
    e2i = find(XLOCI.CHRPOS==190045412079);
    PVXh(:,(9+e2i)) = -1;
    VXh(:,e2i)      = -1;



    % DO NOT YET ALTER THE HOLDOUT VARIANT, TO GET A MEASURE OF IT'S BASELINE
    %VARi = find(XLOCI.CHRPOS==CHRPOS);
    %PVXh(:,(9+VARi)) = 5;
    %VXh(:,VARi)      = 5;


    % NET: GET ACTIVATIONS FOR TRAINING AND HOLDOUT
    ACTnt = net(VXt');  %NN TRAINING
    ACTnh = net(VXh');  %NN HOLDOUT
    [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', ACTnt);
    [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', ACTnh);

    LOOPDATA.CONFU_TR(:,:,ij, 1) = CONFU_TR;
    LOOPDATA.CONFU_HO(:,:,ij, 1) = CONFU_HO;
    LOOPDATA.PERF_TR(ij,:,    1) = PERF_TR;
    LOOPDATA.PERF_HO(ij,:,    1) = PERF_HO;
    LOOPDATA.AREA_TR(:,:,ij,  1) = AREA_TR;
    LOOPDATA.AREA_HO(:,:,ij,  1) = AREA_HO;
    %------------------------------------------------------------------














    %------------------------------------------------------------------
    % TRAINING APOE:  22 23 24 33 34 44
    % HOLDOUT  APOE:  33
    % HOLDOUT  TREM2: ALT/ALT (+1)
    %------------------------------------------------------------------

    [PVXt, VXt, DVXt, DXt, Yt, YDt] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TRPHE,[-1 -0 2 3]);
    [PVXh, VXh, DVXh, DXh, Yh, YDh] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TEPHE,[-1 -0 2 3]);


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE APOE33 ALLELE
    e4i = find(XLOCI.CHRPOS==190045411941);
    e2i = find(XLOCI.CHRPOS==190045412079);
    PVXh(:,(9+e4i)) = -1;
    VXh(:,e4i)      = -1;
    PVXh(:,(9+e2i)) = -1;
    VXh(:,e2i)      = -1;


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE REF/REF TARGET VARIANT
    vi = XLOCI.CHRPOS==CHRPOS;
    PVXh(:,(9+vi)) = -1;
    VXh(:,vi)      = -1;


    % NET: GET ACTIVATIONS FOR TRAINING AND HOLDOUT
    ACTnt = net(VXt');  %NN TRAINING
    ACTnh = net(VXh');  %NN HOLDOUT
    [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', ACTnt);
    [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', ACTnh);

    LOOPDATA.CONFU_TR(:,:,ij, 2) = CONFU_TR;
    LOOPDATA.CONFU_HO(:,:,ij, 2) = CONFU_HO;
    LOOPDATA.PERF_TR(ij,:,    2) = PERF_TR;
    LOOPDATA.PERF_HO(ij,:,    2) = PERF_HO;
    LOOPDATA.AREA_TR(:,:,ij,  2) = AREA_TR;
    LOOPDATA.AREA_HO(:,:,ij,  2) = AREA_HO;
    %------------------------------------------------------------------













    %------------------------------------------------------------------
    % TRAINING APOE:  22 23 24 33 34 44
    % HOLDOUT  APOE:  33
    % HOLDOUT  VARS:  REFALT/ALT (+5)
    %------------------------------------------------------------------
    [PVXt, VXt, DVXt, DXt, Yt, YDt] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TRPHE,[-1 -0 2 3]);
    [PVXh, VXh, DVXh, DXh, Yh, YDh] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TEPHE,[-1 -0 2 3]);


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE APOE33 ALLELE
    e4i = find(XLOCI.CHRPOS==190045411941);
    e2i = find(XLOCI.CHRPOS==190045412079);
    PVXh(:,(9+e4i)) = -1;
    VXh(:,e4i)      = -1;
    PVXh(:,(9+e2i)) = -1;
    VXh(:,e2i)      = -1;


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE REF/REF TARGET VARIANT
    vi = XLOCI.CHRPOS==CHRPOS;
    PVXh(:,(9+vi)) = 2;
    VXh(:,vi)      = 2;


    % NET: GET ACTIVATIONS FOR TRAINING AND HOLDOUT
    ACTnt = net(VXt');  %NN TRAINING
    ACTnh = net(VXh');  %NN HOLDOUT
    [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', ACTnt);
    [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', ACTnh);

    LOOPDATA.CONFU_TR(:,:,ij, 3) = CONFU_TR;
    LOOPDATA.CONFU_HO(:,:,ij, 3) = CONFU_HO;
    LOOPDATA.PERF_TR(ij,:,    3) = PERF_TR;
    LOOPDATA.PERF_HO(ij,:,    3) = PERF_HO;
    LOOPDATA.AREA_TR(:,:,ij,  3) = AREA_TR;
    LOOPDATA.AREA_HO(:,:,ij,  3) = AREA_HO;
    %------------------------------------------------------------------










    %------------------------------------------------------------------
    % TRAINING APOE:  22 23 24 33 34 44
    % HOLDOUT  APOE:  33
    % HOLDOUT  VARS:  ALT/ALT (+5)
    %------------------------------------------------------------------
    [PVXt, VXt, DVXt, DXt, Yt, YDt] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TRPHE,[-1 -0 2 3]);
    [PVXh, VXh, DVXh, DXh, Yh, YDh] = mkdx(XLOCI,XCASE,XCTRL,XUSNP,TEPHE,[-1 -0 2 3]);


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE APOE33 ALLELE
    e4i = find(XLOCI.CHRPOS==190045411941);
    e2i = find(XLOCI.CHRPOS==190045412079);
    PVXh(:,(9+e4i)) = -1;
    VXh(:,e4i)      = -1;
    PVXh(:,(9+e2i)) = -1;
    VXh(:,e2i)      = -1;


    % ARTIFICIALLY MAKE HOLDOUT PARTICIPANTS HAVE ALT/ALT TARGET VARIANT
    vi = XLOCI.CHRPOS==CHRPOS;
    PVXh(:,(9+vi)) = 3;
    VXh(:,vi)      = 3;


    % NET: GET ACTIVATIONS FOR TRAINING AND HOLDOUT
    ACTnt = net(VXt');  %NN TRAINING
    ACTnh = net(VXh');  %NN HOLDOUT
    [CONFU_TR, PERF_TR, AREA_TR] = confusionmx(Yt', ACTnt);
    [CONFU_HO, PERF_HO, AREA_HO] = confusionmx(Yh', ACTnh);

    LOOPDATA.CONFU_TR(:,:,ij, 4) = CONFU_TR;
    LOOPDATA.CONFU_HO(:,:,ij, 4) = CONFU_HO;
    LOOPDATA.PERF_TR(ij,:,    4) = PERF_TR;
    LOOPDATA.PERF_HO(ij,:,    4) = PERF_HO;
    LOOPDATA.AREA_TR(:,:,ij,  4) = AREA_TR;
    LOOPDATA.AREA_HO(:,:,ij,  4) = AREA_HO;
    %------------------------------------------------------------------














%==========================================================================
%==========================================================================
% 
end
%
%==========================================================================
%==========================================================================
clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP LOOPDATA kk ij...
VLOCI VCASE VCTRL VUSNP VTRCASE VTRCTRL VTECASE VTECTRL SNPi XLOCI...
XCASE XCTRL XUSNP TRPHE TEPHE PVXt DVXt PVXh DVXh VXt VXh Yt Yh...
YDt YDh DXt DXh netq netd net 
%----------------------------------------------------------------------










%% SAVE LOOP DATA
%----------------------------------------------------------------------
clc; clearvars -except P ADSP INFO PHEN LOCI CASE CTRL USNP LOOPDATA kk ij...
VLOCI VCASE VCTRL VUSNP VTRCASE VTRCTRL VTECASE VTECTRL SNPi XLOCI...
XCASE XCTRL XUSNP TRPHE TEPHE PVXt DVXt PVXh DVXh VXt VXh Yt Yh...
YDt YDh DXt DXh netq netd net
%----------------------------------------------------------------------


GENE   = ADSP.SNP.GENE{kk};
CHRPOS = ADSP.SNP.CHRPOS(kk);



%------------------------------------------------------------------
% TRAINING APOE:  22 23 24 33 34 44
% HOLDOUT  APOE:  33
% HOLDOUT  VARI:  NATIVE
%------------------------------------------------------------------
fh01 = figure('Units','normalized','OuterPosition',[.01 .06 .55 .37],'Color','w');
ax1 = axes('Position',[.07 .16 .61 .80],'Color','none');
ax2 = axes('Position',[.78 .16 .21 .80],'Color','none');

%AREA:[X, CASE_OK, CTRL_OK, CASE_BAD, CTRL_BAD] maybe?
AREAS = mean(LOOPDATA.AREA_HO(:,:,:,1)  ,3);

%PERF:[MU_CASE, MU_CTRL, MU_ALL, HIMU_CASE, HIMU_CTRL, HIMU_ALL]
PERFS = mean(LOOPDATA.PERF_HO(:,:,1)) .* 100;

%---PLOT AREAGRAM ---------------------
    axes(ax1) 
area(AREAS(:,1),AREAS(:,2:5))
    legend({'Case Miss','Ctrl Miss',...
            'Case Hit','Ctrl Hit'},...
            'Location','best');
    ylabel('Count')
    ax1.FontSize=16;
    %title('Classifier Performance Area');

%---BAR GRAPH ------------------------------------------
    axes(ax2)
bar(([ PERFS(4) , PERFS(5) , PERFS(6) ]),.5, 'FaceColor',[.31 .31 .31]); 
    hold on; 
bar(([ PERFS(1) , PERFS(2) , PERFS(3) ]),.20,'FaceColor',[.95 .85 .50]);
    grid on; ylabel('Pct. Correct')
    legend({'Top 25%','All'},'Location','Northwest','NumColumns',2)
    ax2.YLim = [0 116]; 
    ax2.YTick = [0 25 50 75 100]; 
    ax2.XTickLabels = {'CASE','CTRL','ALL'};
    ax2.XTickLabelRotation = 33;
    ax2.FontSize=16;
    %title('Performance Summary')
%----------------------------------------------------------------------
pause(1)
set(gcf, 'PaperPositionMode', 'auto');
%dt=char(datetime(datetime,'Format','yyyy-MM-dd-HH-mm-ss'));
saveas(gcf, [P.datadumpdir P.f GENE '_' num2str(CHRPOS) '_ANYANY.png']);
pause(1)
%---------------------------------------------------------------------- 




%------------------------------------------------------------------
% TRAINING APOE:  22 23 24 33 34 44
% HOLDOUT  APOE:  33
% HOLDOUT  VARI: -1
%------------------------------------------------------------------
fh02 = figure('Units','normalized','OuterPosition',[.01 .06 .55 .37],'Color','w');
ax1 = axes('Position',[.07 .16 .61 .80],'Color','none');
ax2 = axes('Position',[.78 .16 .21 .80],'Color','none');

%AREA:[X, CASE_OK, CTRL_OK, CASE_BAD, CTRL_BAD] maybe?
AREAS = mean(LOOPDATA.AREA_HO(:,:,:,2)  ,3);

%PERF:[MU_CASE, MU_CTRL, MU_ALL, HIMU_CASE, HIMU_CTRL, HIMU_ALL]
PERFS = mean(LOOPDATA.PERF_HO(:,:,2)) .* 100;

%---PLOT AREAGRAM ---------------------
    axes(ax1) 
area(AREAS(:,1),AREAS(:,2:5))
    legend({'Case Miss','Ctrl Miss',...
            'Case Hit','Ctrl Hit'},...
            'Location','best');
    ylabel('Count')
    ax1.FontSize=16;
    %title('Classifier Performance Area');

%---BAR GRAPH ------------------------------------------
    axes(ax2)
bar(([ PERFS(4) , PERFS(5) , PERFS(6) ]),.5, 'FaceColor',[.31 .31 .31]); 
    hold on; 
bar(([ PERFS(1) , PERFS(2) , PERFS(3) ]),.20,'FaceColor',[.95 .85 .50]);
    grid on; ylabel('Pct. Correct')
    legend({'Top 25%','All'},'Location','Northwest','NumColumns',2)
    ax2.YLim = [0 116]; 
    ax2.YTick = [0 25 50 75 100]; 
    ax2.XTickLabels = {'CASE','CTRL','ALL'};
    ax2.XTickLabelRotation = 33;
    ax2.FontSize=16;
    %title('Performance Summary')
%----------------------------------------------------------------------
pause(1)
set(gcf, 'PaperPositionMode', 'auto');
%dt=char(datetime(datetime,'Format','yyyy-MM-dd-HH-mm-ss'));
saveas(gcf, [P.datadumpdir P.f GENE '_' num2str(CHRPOS) '_REFREF.png']);
pause(1)
%---------------------------------------------------------------------- 


%------------------------------------------------------------------
% TRAINING APOE:  22 23 24 33 34 44
% HOLDOUT  APOE:  33
% HOLDOUT  VARI:  2
%------------------------------------------------------------------
fh02 = figure('Units','normalized','OuterPosition',[.01 .06 .55 .37],'Color','w');
ax1 = axes('Position',[.07 .16 .61 .80],'Color','none');
ax2 = axes('Position',[.78 .16 .21 .80],'Color','none');

%AREA:[X, CASE_OK, CTRL_OK, CASE_BAD, CTRL_BAD] maybe?
AREAS = mean(LOOPDATA.AREA_HO(:,:,:,3)  ,3);

%PERF:[MU_CASE, MU_CTRL, MU_ALL, HIMU_CASE, HIMU_CTRL, HIMU_ALL]
PERFS = mean(LOOPDATA.PERF_HO(:,:,3)) .* 100;

%---PLOT AREAGRAM ---------------------
    axes(ax1) 
area(AREAS(:,1),AREAS(:,2:5))
    legend({'Case Miss','Ctrl Miss',...
            'Case Hit','Ctrl Hit'},...
            'Location','best');
    ylabel('Count')
    ax1.FontSize=16;
    %title('Classifier Performance Area');

%---BAR GRAPH ------------------------------------------
    axes(ax2)
bar(([ PERFS(4) , PERFS(5) , PERFS(6) ]),.5, 'FaceColor',[.31 .31 .31]); 
    hold on; 
bar(([ PERFS(1) , PERFS(2) , PERFS(3) ]),.20,'FaceColor',[.95 .85 .50]);
    grid on; ylabel('Pct. Correct')
    legend({'Top 25%','All'},'Location','Northwest','NumColumns',2)
    ax2.YLim = [0 116]; 
    ax2.YTick = [0 25 50 75 100]; 
    ax2.XTickLabels = {'CASE','CTRL','ALL'};
    ax2.XTickLabelRotation = 33;
    ax2.FontSize=16;
    %title('Performance Summary')
%----------------------------------------------------------------------
pause(1)
set(gcf, 'PaperPositionMode', 'auto');
%dt=char(datetime(datetime,'Format','yyyy-MM-dd-HH-mm-ss'));
saveas(gcf, [P.datadumpdir P.f GENE '_' num2str(CHRPOS) '_REFALT.png']);
pause(1)
%---------------------------------------------------------------------- 





%------------------------------------------------------------------
% TRAINING APOE:  22 23 24 33 34 44
% HOLDOUT  APOE:  33
% HOLDOUT  VARI:  3
%------------------------------------------------------------------
fh02 = figure('Units','normalized','OuterPosition',[.01 .06 .55 .37],'Color','w');
ax1 = axes('Position',[.07 .16 .61 .80],'Color','none');
ax2 = axes('Position',[.78 .16 .21 .80],'Color','none');

%AREA:[X, CASE_OK, CTRL_OK, CASE_BAD, CTRL_BAD] maybe?
AREAS = mean(LOOPDATA.AREA_HO(:,:,:,4)  ,3);

%PERF:[MU_CASE, MU_CTRL, MU_ALL, HIMU_CASE, HIMU_CTRL, HIMU_ALL]
PERFS = mean(LOOPDATA.PERF_HO(:,:,4)) .* 100;

%---PLOT AREAGRAM ---------------------
    axes(ax1) 
area(AREAS(:,1),AREAS(:,2:5))
    legend({'Case Miss','Ctrl Miss',...
            'Case Hit','Ctrl Hit'},...
            'Location','best');
    ylabel('Count')
    ax1.FontSize=16;
    %title('Classifier Performance Area');

%---BAR GRAPH ------------------------------------------
    axes(ax2)
bar(([ PERFS(4) , PERFS(5) , PERFS(6) ]),.5, 'FaceColor',[.31 .31 .31]); 
    hold on; 
bar(([ PERFS(1) , PERFS(2) , PERFS(3) ]),.20,'FaceColor',[.95 .85 .50]);
    grid on; ylabel('Pct. Correct')
    legend({'Top 25%','All'},'Location','Northwest','NumColumns',2)
    ax2.YLim = [0 116]; 
    ax2.YTick = [0 25 50 75 100]; 
    ax2.XTickLabels = {'CASE','CTRL','ALL'};
    ax2.XTickLabelRotation = 33;
    ax2.FontSize=16;
    %title('Performance Summary')
%----------------------------------------------------------------------
pause(1)
set(gcf, 'PaperPositionMode', 'auto');
%dt=char(datetime(datetime,'Format','yyyy-MM-dd-HH-mm-ss'));
saveas(gcf, [P.datadumpdir P.f GENE '_' num2str(CHRPOS) '_ALTALT.png']);
pause(1)
%---------------------------------------------------------------------- 



%------------------------------------------%
P.SAVEPATH = [P.datadumpdir P.f GENE '_' num2str(CHRPOS) '.mat'];
save(P.SAVEPATH,'LOOPDATA','P','INFO');
disp('File saved...'); disp(P.SAVEPATH)
%------------------------------------------%







%##########################################################################
%##########################################################################
% 
end
%
%##########################################################################
%##########################################################################






