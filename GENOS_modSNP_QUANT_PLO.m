%% GENOS_FISHP
%{
% 
%--------------------------------------------------------------------------
% 
% SUMMARY TABLE OF THE 24 COHORTS
% 
% COHID    CONSOR    STUDY        COHORT    CASES    CTRLS    TOTAL    %CASE    EQL  BRAAK ID GOOD
% 01       DGC       Adult_Chng    ACT        323      945     1268       25    323    1   01    1
% 02       ADGC      AD_Centers    ADC       2438      817     3255       75    817    0   02    1
% 03       CHARGE    Athrosclro    ASC         39       18       57       68     18    0   03    0
% 04       CHARGE    Aus_Stroke    SKE        121        5      126       96      5    0   04    0
% 05       ADGC      ChiT_Aging    CHA         27      204      231       12     27    0   05    0
% 06       CHARGE    CardioHlth    CHS        250      583      833       30    250    1   06    1
% 07       ADGC      Hispanic_S    HSP        160      171      331       48    160    0   07    0
% 08       CHARGE    Erasmus_Er    ERF         45        0       45      100      0    0   08    0
% 09       CHARGE    Framingham    FHS        157      424      581       27    157    1   09    1
% 10       ADGC      Gene_Diffs    GDF        111       96      207       54     96    1   10    1
% 11       ADGC      NIA_LOAD      LOD        367      109      476       77    109    1   11    1
% 12       ADGC      Aging_Proj    MAP        138      277      415       33    138    1   12    1
% 13       ADGC      Mayo_Clini    MAY        250       99      349       72     99    1   13    1
% 14       ADGC      Miami_Univ    MIA        186       14      200       93     14    1   14    0
% 15       ADGC      AD_Genetic    MIR        316       15      331       95     15    0   15    0
% 16       ADGC      Mayo_cl_PD    MPD          0       20       20        0      0    1   16    0
% 17       ADGC      NationC_AD    NCA        160        0      160      100      0    1   17    0
% 18       ADGC      Wash_Unive    RAS         46        0       46      100      0    1   18    0
% 19       ADGC      Relig_Ordr    ROS        154      197      351       44    154    1   19    1
% 20       CHARGE    RotterdamS    RDS        276      813     1089       25    276    0   20    1
% 21       ADGC      Texas_AD_S    TAR        132       12      144       92     12    0   21    0
% 22       ADGC      Un_Toronto    TOR          9        0        9      100      0    0   22    0
% 23       ADGC      Vanderbilt    VAN        210       26      236       89     26    1   23    1
% 24       ADGC      WashNY_Age    WCA         34      116      150       23     34    0   24    1
% 
% 
% GOODCOHORTS = [1 2         6 7   9 10 11 12 13               19 20     23 24]
% BRAKCOHORTS = [1           6     9 10 11 12 13 14   16 17 18 19        23   ]
%--------------------------------------------------------------------------
% 
% THE ADSP DATASET - WHAT'S BEING IMPORTED?
%
% 
% The dataset that will be loaded in STEP-1 below will import 5 variables
% and store them into a structural array named 'ADSP'. If you type ADSP
% into the command prompt you will see...
% 
% 
% >> ADSP
% 
% ADSP = 
%   struct with fields:
% 
%     PHEN: [10910�22 table]
%     LOCI: [94483�24 table]
%     CASE: {94483�1 cell}
%     CTRL: {94483�1 cell}
%     USNP: {94483�1 cell}
% 
% 
% ...(maybe not in this specific order) the 5 container variables.
% 
% 
% PHEN    a table containing the phenotype information for each
%         participant. If you type head(ADSP.PHEN) you can see what
%         data each column contains.
% 
% 
% LOCI    a table containing genotype info for each exome variant locus.
%         if you type head(ADSP.LOCI) you can see what data each column
%         contains.
% 
% 
% 
% CASE    the last three are cell arrays, containing a list of 
% CTRL    participant IDs & HET/HOM status. Each have 1 cell per row
% USNP    of LOCI (~94483 cells); they are (at least upon import) 
%         pre-sorted in corresponding order, which allows us to
%         iterate over each loci/cell and tally each HET (+1) or 
%         HOM (+2) that matches subsets of participant IDs. (there
%         is an optimized function specifically designed to
%         perform this task, as you will see below).
%         
% 
%--------------------------------------------------------------------------
%}
%% GENOS: 
%==========================================================================
%% STEP-1: LOAD THE DATASET
%==========================================================================
close all; clear; clc; rng('shuffle');
P.home = fileparts(which('GENOS.m')); cd(P.home);
P.funs = [P.home filesep 'genos_functions'];
P.mfuns = [P.funs filesep 'genos_main_functions'];
P.other = [P.home filesep 'genos_other'];
P.data = [P.home filesep 'genos_data'];
% P.data = 'F:\GENOSDATA';
addpath(join(string(struct2cell(P)),pathsep,1))
cd(P.home); P.f = filesep;


ADSP = load('GENOSDATA.mat');


clc; clearvars -except P ADSP
%==========================================================================
%% (GENOX) PERTURB TEST OPTIONS & FOLDERS 
%==========================================================================
clc; clearvars -except P ADSP


% LOCI = ADSP.LOCI;
% min(LOCI.CASEALT + LOCI.CTRLALT)
% min(LOCI.CTRLALT)



RUN = 'RUN10_PLO_NOAPOE';
% RUN = 'RUN9_PLO';

P.serial.DIRroot = [P.home P.f 'genos_data' P.f 'modSNP' P.f RUN];
P.serial.DIRmat  = [P.serial.DIRroot P.f 'MAT'];
P.serial.DIRout  = [P.serial.DIRroot P.f 'OUT'];
P.serial.DIRdat  = [P.serial.DIRroot P.f 'DAT'];



% GET PATHS TO MAT FILES
%------------------------------------------------------
P.LDATA.w = what(P.serial.DIRmat);
P.LDATA.finfo = dir(P.LDATA.w.path);
P.LDATA.finames = {P.LDATA.finfo.name};
c=~cellfun(@isempty,regexp(P.LDATA.finames,'((\S)+(\.mat+))'));
P.LDATA.finames = string(P.LDATA.finames(c)');
P.LDATA.folder = P.LDATA.finfo.folder;
P.LDATA.fipaths = fullfile(P.LDATA.folder,P.LDATA.finames);
disp(P.LDATA.fipaths); disp(P.LDATA.finames);
disp('TOTAL MAT FILES:'); disp(numel(P.LDATA.finames));



% LDATA = load(P.LDATA.fipaths{1});



clearvars -except P ADSP
%==========================================================================
%% GET SERIAL STATS
%==========================================================================
clc; clearvars -except P ADSP


DATA = load(P.LDATA.fipaths{1});

LOOP.GENECHRPOS  = DATA.LOOPDATA.GENECHRPOS;
LOOP.XLOCI       = DATA.LOOPDATA.XLOCI;
LOOP.NETS        = DATA.LOOPDATA.NETS;

LOOP.PVXt   = DATA.LOOPDATA.PVXt;
LOOP.PVXh   = DATA.LOOPDATA.PVXh;


LOOP.NNNATt = DATA.LOOPDATA.NNNATt;
LOOP.NNNATh = DATA.LOOPDATA.NNNATh;
LOOP.NNREFt = DATA.LOOPDATA.NNREFt;
LOOP.NNREFh = DATA.LOOPDATA.NNREFh;
LOOP.NNALTt = DATA.LOOPDATA.NNALTt;
LOOP.NNALTh = DATA.LOOPDATA.NNALTh;


clc; clearvars -except P ADSP LOOP
%==========================================================================


























%==========================================================================
%% BUILD LOCI TABLE
%==========================================================================
clc; clearvars -except P ADSP LOOP


% GET LOOP PARAMETERS FROM DATA
%----------------------------------------
XLOCIS = LOOP.XLOCI';
XLOCI = XLOCIS{1};

P.SnpSets     = numel(P.LDATA.fipaths);
P.LoopsPerSet = size(XLOCIS,1);
P.nTopTarg    = size(XLOCI,1);
P.nTarg       = sum(XLOCI.TRFISHP==0);
P.nSNP        = P.SnpSets * P.nTarg;


fprintf('N MAT FILES: %14.f \n',P.SnpSets);
fprintf('N LOOPS PER TARGET SET: %3.f \n',P.LoopsPerSet);
fprintf('N TARGETS + TOPSNPS: %6.f \n',P.nTopTarg);
fprintf('N TARGETS: %16.f \n',P.nTarg);



%==========================================================================
for i = 1:P.SnpSets
%==========================================================================
disp(i);


% LOAD DATASET FROM MAT FILE
DATA    = load(P.LDATA.fipaths{i});
XLOCIS  = DATA.LOOPDATA.XLOCI';




% EXTRACT VALUES FROM EACH LOOP
%----------------------------------------
for j = 1:P.LoopsPerSet

    XLOCI         = XLOCIS{j};

    % SET TRAINING FISHP BACK TO REAL VALUE FROM FISHP
    XLOCI.TRFISHP    = XLOCI.FISHP;
    XLOCI.FISHP      = XLOCI.OKFISHP;
    XLOCI.FISHOR     = XLOCI.OKFISHOR;
    XLOCI.CASEREF    = XLOCI.OKCASEREF;
    XLOCI.CASEALT    = XLOCI.OKCASEALT;
    XLOCI.CTRLREF    = XLOCI.OKCTRLREF;
    XLOCI.CTRLALT    = XLOCI.OKCTRLALT;

    XLOCI         = XLOCI(1:P.nTarg,[1 3:8 13:18 25:32 41:44]);
    XLOCI.TARGET  = (1:size(XLOCI,1))';
    XLOCI.SET     = (zeros(size(XLOCI,1),1) + i);
    XLOCI.srtVAL  = log(abs(-log(XLOCI.FISHP)))+abs(-log(XLOCI.FISHOR));

    if j == 1
        jLOC = XLOCI;
    else
        if any(~strcmp(jLOC.GENE,XLOCI.GENE)); keyboard; end
        jLOC.TRCASEREF = jLOC.TRCASEREF + XLOCI.TRCASEREF;
        jLOC.TRCTRLREF = jLOC.TRCTRLREF + XLOCI.TRCTRLREF;
        jLOC.TRCASEALT = jLOC.TRCASEALT + XLOCI.TRCASEALT;
        jLOC.TRCTRLALT = jLOC.TRCTRLALT + XLOCI.TRCTRLALT;
        jLOC.TECASEREF = jLOC.TECASEREF + XLOCI.TECASEREF;
        jLOC.TECTRLREF = jLOC.TECTRLREF + XLOCI.TECTRLREF;
        jLOC.TECASEALT = jLOC.TECASEALT + XLOCI.TECASEALT;
        jLOC.TECTRLALT = jLOC.TECTRLALT + XLOCI.TECTRLALT;
        jLOC.TRFISHP   = jLOC.TRFISHP   + XLOCI.TRFISHP;
        jLOC.TEFISHP   = jLOC.TEFISHP   + XLOCI.TEFISHP;
        jLOC.TRFISHOR  = jLOC.TRFISHOR  + XLOCI.TRFISHOR;
        jLOC.TEFISHOR  = jLOC.TEFISHOR  + XLOCI.TEFISHOR;
    end

end

    jLOC.TRCASEREF = round(jLOC.TRCASEREF ./ P.LoopsPerSet);
    jLOC.TRCTRLREF = round(jLOC.TRCTRLREF ./ P.LoopsPerSet);
    jLOC.TRCASEALT = round(jLOC.TRCASEALT ./ P.LoopsPerSet);
    jLOC.TRCTRLALT = round(jLOC.TRCTRLALT ./ P.LoopsPerSet);
    jLOC.TECASEREF = round(jLOC.TECASEREF ./ P.LoopsPerSet);
    jLOC.TECTRLREF = round(jLOC.TECTRLREF ./ P.LoopsPerSet);
    jLOC.TECASEALT = round(jLOC.TECASEALT ./ P.LoopsPerSet);
    jLOC.TECTRLALT = round(jLOC.TECTRLALT ./ P.LoopsPerSet);
    jLOC.TRFISHP   = jLOC.TRFISHP   ./ P.LoopsPerSet;
    jLOC.TEFISHP   = jLOC.TEFISHP   ./ P.LoopsPerSet;
    jLOC.TRFISHOR  = jLOC.TRFISHOR  ./ P.LoopsPerSet;
    jLOC.TEFISHOR  = jLOC.TEFISHOR  ./ P.LoopsPerSet;

    if i == 1
    iLOC = jLOC;
    else
    iLOC = [iLOC; jLOC];
    end
end
%==========================================================================
%% EXPORT TABLE TO CSV FILE
%==========================================================================
clc; clearvars -except P ADSP LOOP iLOC


writetable(  iLOC  ,[P.serial.DIRout P.f 'iLOC.csv']);



% return
%==========================================================================
































































%##########################################################################
%%                         CREATE iSNP
%##########################################################################
% P.serial.DIRroot = [P.home P.f 'genos_data' P.f 'SERIAL' P.f 'RUN'];
% P.serial.DIRmat  = [P.serial.DIRroot P.f 'MAT'];
% P.serial.DIRimg  = [P.serial.DIRroot P.f 'IMG'];
% P.serial.DIRout  = [P.serial.DIRroot P.f 'OUT'];




%==========================================================================
%% LABEL GOOD COHORTS & BRAAK COHORTS
%==========================================================================
clc; clearvars -except P ADSP

GOODCOHORTS = [1 2 6 7 9 10 11 12 13 19 20 23 24];
BRAKCOHORTS = [1 6 9 10 11 12 13 14 16 17 18 19 23];

PHEN = ADSP.PHEN;

PHEN.GOODCOH = sum(PHEN.COHORTNUM == GOODCOHORTS,2)>0;
PHEN.BRAKCOH = sum(PHEN.COHORTNUM == BRAKCOHORTS,2)>0;

[G,ID] = findgroups(PHEN.COHORTNUM(PHEN.GOODCOH==1));
disp('Good cohorts:'); disp(ID');

[G,ID] = findgroups(PHEN.COHORTNUM(PHEN.BRAKCOH==1));
disp('Braak cohorts:'); disp(ID');


PHEN = sortrows(PHEN,{'GOODCOH','COHORTNUM','SRR'},...
                     {'descend','ascend','ascend'});

ADSP.PHEN = PHEN;


clearvars -except P ADSP
%==========================================================================
%% GET SERIAL STATS
%==========================================================================
clc; clearvars -except P ADSP


DATA = load(P.LDATA.fipaths{1});

LOOP.GCHRPOS  = DATA.LOOPDATA.GENECHRPOS;
LOOP.XLOCI    = DATA.LOOPDATA.XLOCI;
LOOP.NETS     = DATA.LOOPDATA.NETS;

LOOP.PVXt     = DATA.LOOPDATA.PVXt;
LOOP.PVXh     = DATA.LOOPDATA.PVXh;


LOOP.NNNATt   = DATA.LOOPDATA.NNNATt;
LOOP.NNNATh   = DATA.LOOPDATA.NNNATh;
LOOP.NNREFt   = DATA.LOOPDATA.NNREFt;
LOOP.NNREFh   = DATA.LOOPDATA.NNREFh;
LOOP.NNALTt   = DATA.LOOPDATA.NNALTt;
LOOP.NNALTh   = DATA.LOOPDATA.NNALTh;






clc; clearvars -except P ADSP LOOP
%==========================================================================
%% GET SERIAL STATS
%==========================================================================
clc; clearvars -except P ADSP LOOP





% GET LOOP PARAMETERS FROM DATA
%----------------------------------------
XLOCIS = LOOP.XLOCI';
XLOCI  = XLOCIS{1};

P.SnpSets     = numel(P.LDATA.fipaths);
P.LoopsPerSet = size(XLOCIS,1);
P.nTopTarg    = size(XLOCI,1);
P.nTarg       = sum(XLOCI.TRFISHP==0);
P.nSNP        = P.SnpSets * P.nTarg;


fprintf('N SNP SETS (TOTAL MAT FILES): %5.f \n',P.SnpSets);
fprintf('N LOOPS PER SNP SET: %14.f \n',P.LoopsPerSet);
fprintf('N PER SET TARGETS+TOPSNPS: %8.f \n',P.nTopTarg);
fprintf('N PER SET TARGETS: %16.f \n',P.nTarg);
fprintf('N TOTAL SNP TARGETS: %14.f \n',P.nSNP);






%==========================================================================
%%                          PHEN
%==========================================================================
clc; clearvars -except P ADSP LOOP


% iPHEN (10910 x 500)
%----------------
iPHEN  = ADSP.PHEN;
iPHEN.PVX = nan(size(iPHEN,1),P.nSNP);
iPHEN.REF = nan(size(iPHEN,1),P.nSNP);
iPHEN.ALT = nan(size(iPHEN,1),P.nSNP);
iPHEN.DIF = nan(size(iPHEN,1),P.nSNP);
iPHEN.NAT = nan(size(iPHEN,1),P.nSNP);




% i=1;j=1;
% return
%==========================================================================
for i = 1:P.SnpSets
%==========================================================================
disp(i);


% LOAD DATASET FROM MAT FILE
%----------------
DATA            = load(P.LDATA.fipaths{i});
LOOP.PVXt       = DATA.LOOPDATA.PVXt;
LOOP.PVXh       = DATA.LOOPDATA.PVXh;
LOOP.NNREFt     = DATA.LOOPDATA.NNREFt;
LOOP.NNREFh     = DATA.LOOPDATA.NNREFh;
LOOP.NNALTt     = DATA.LOOPDATA.NNALTt;
LOOP.NNALTh     = DATA.LOOPDATA.NNALTh;
LOOP.NNNATt     = DATA.LOOPDATA.NNNATt;
LOOP.NNNATh     = DATA.LOOPDATA.NNNATh;



% jPHEN (10910 x 10 x 5)
%----------------
jPHEN = ADSP.PHEN;
jPHEN.PVX = nan(size(jPHEN,1),P.nTarg,P.LoopsPerSet);
jPHEN.REF = nan(size(jPHEN,1),P.nTarg,P.LoopsPerSet);
jPHEN.ALT = nan(size(jPHEN,1),P.nTarg,P.LoopsPerSet);
jPHEN.NAT = nan(size(jPHEN,1),P.nTarg,P.LoopsPerSet);



% kPHEN (10910 x 10)
%----------------
kPHEN = ADSP.PHEN;
kPHEN.PVX = nan(size(kPHEN,1),P.nTarg);
kPHEN.REF = nan(size(kPHEN,1),P.nTarg);
kPHEN.ALT = nan(size(kPHEN,1),P.nTarg);
kPHEN.DIF = nan(size(kPHEN,1),P.nTarg);
kPHEN.NAT = nan(size(kPHEN,1),P.nTarg);




%----------------------------------------
for j = 1:P.LoopsPerSet


% GET NN MATRICES & NN OUTPUTS
PVX = [LOOP.PVXt(:,:,j); LOOP.PVXh(:,:,j)];
PVX(isnan(PVX(:,1)),:)=[];
REF = [LOOP.NNREFt(:,:,j); LOOP.NNREFh(:,:,j)];
REF(isnan(REF(:,1)),:)=[];
ALT = [LOOP.NNALTt(:,:,j); LOOP.NNALTh(:,:,j)];
ALT(isnan(ALT(:,1)),:)=[];
NAT = [LOOP.NNNATt(:,:,j); LOOP.NNNATh(:,:,j)];
NAT(isnan(NAT(:,1)),:)=[];



% DETERMINE ORDER OF PARTICIPANTS IN PVX REF ALT
[~,ai] = ismember( jPHEN.SRR, PVX(:,1) );  aj = ai(ai>0);
[~,bi] = ismember( jPHEN.SRR, REF(:,1) );  bj = bi(bi>0);
[~,ci] = ismember( jPHEN.SRR, ALT(:,1) );  cj = ci(ci>0);
[~,ni] = ismember( jPHEN.SRR, NAT(:,1) );  nj = ni(ni>0);


% jPHEN.PVX(ai>0,:,j) = PVX(aj,10:10+P.nTarg);
% jPHEN.REF(bi>0,:,j) = REF(bj,10:10+P.nTarg);
% jPHEN.ALT(ci>0,:,j) = ALT(cj,10:10+P.nTarg);
% jPHEN.NAT(bi>0,:,j) = REF(cj,end);


jPHEN.PVX(ai>0,:,j) = PVX(aj,10:(10+P.nTarg-1));
jPHEN.REF(bi>0,:,j) = REF(bj,10:(10+P.nTarg-1));
jPHEN.ALT(ci>0,:,j) = ALT(cj,10:(10+P.nTarg-1));
jPHEN.NAT(ni>0,:,j) = NAT(nj,10:(10+P.nTarg-1));


end
%----------------------------------------



kPHEN.PVX = nanmean(jPHEN.PVX,3);
kPHEN.REF = nanmean(jPHEN.REF,3);
kPHEN.ALT = nanmean(jPHEN.ALT,3);
kPHEN.NAT = nanmean(jPHEN.NAT,3);
kPHEN.DIF = kPHEN.ALT - kPHEN.REF;


n=P.nTarg;
iPHEN.PVX(:,(i*n-n+1):(i*n)) = kPHEN.PVX;
iPHEN.REF(:,(i*n-n+1):(i*n)) = kPHEN.REF;
iPHEN.ALT(:,(i*n-n+1):(i*n)) = kPHEN.ALT;
iPHEN.DIF(:,(i*n-n+1):(i*n)) = kPHEN.DIF;
iPHEN.NAT(:,(i*n-n+1):(i*n)) = kPHEN.NAT;

end
%==========================================================================






%==========================================================================
%% CLEANUP iPHEN
%==========================================================================
clc; clearvars -except P ADSP LOOP iPHEN


iSNP = iPHEN;
summary(iSNP);


r = sum(isnan(iSNP.REF),2);
iSNP(r>0,:) = [];


clc; clearvars -except P ADSP LOOP iSNP
%==========================================================================
%% EXPORT iSNP
%==========================================================================
clc; clearvars -except P ADSP LOOP iSNP


writetable(  iSNP  ,  [P.serial.DIRout P.f 'iSNP.csv']);



% return
%==========================================================================
%% IMPORT iLOC CSV FILES AND CREATE MAT FILE WITH: iSNP iLOC LOOP
%==========================================================================
clc; clearvars -except P ADSP LOOP iSNP

iLOC = readtable([P.serial.DIRout P.f 'iLOC.csv']);
iLOC.CHRPOS = uint64(iLOC.CHRPOS);


if ~exist('iSNP')

iSNP = readtable([P.serial.DIRout P.f 'iSNP.csv']);
iSNP.CHRPOS = uint64(iSNP.CHRPOS);

V = string(iSNP.Properties.VariableNames');
PVXidx = contains(V,'PVX'); %(24:end,:)
REFidx = contains(V,'REF');
ALTidx = contains(V,'ALT');
DIFidx = contains(V,'DIF');
NATidx = contains(V,'NAT');

PVX = table2array(iSNP(:,PVXidx));
REF = table2array(iSNP(:,REFidx));
ALT = table2array(iSNP(:,ALTidx));
DIF = table2array(iSNP(:,DIFidx));
NAT = table2array(iSNP(:,NATidx));

iSNP(:,24:end) = [];
iSNP.PVX = PVX;
iSNP.REF = REF;
iSNP.ALT = ALT;
iSNP.DIF = DIF;
iSNP.NAT = NAT;
end



save([P.serial.DIRout P.f 'SNP.mat'],'iSNP','iLOC')
disp('done')


% L = load([P.serial.DIRout P.f 'SNP.mat'],'iSNP','iLOC');
% head(iSNP); summary(iSNP);






