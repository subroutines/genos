function [ADMX,SNPCASE,SNPCTRL,PHE,CASEID,CTRLID,IDVX, ...
ASYMX,ASYCASE,ASYCTRL,ADNN,caMX,coMX] = GENOS_COVAR_PREP(varargin)
%% getCOOCCUR.m 



if nargin>0

    disp('LOADING DATASET')
    load(varargin{1});

else

    disp('LOADING DATASET')
    load('GENOMICSDATA_EQUAL_PRO.mat')

end



try disp(ADMX(1:5,:))
catch
    ADMX = DATATABLE;
end


clearvars -except ADMX SNPCASE SNPCTRL PHE






%% DETERMINE SRRs IN DATASET AND CREATE CASEID/CTRLID LISTS
disp('DETERMINING SRRs IN DATASET AND CREATING CASEID/CTRLID LISTS')

try disp(CASEID(1:5))        % IF 'CASEID' HAS NOT BEEN GENERATED...
catch



% DETERMINE WHO IS IN THIS DATASET
[IDVX] = getSRR(ADMX,SNPCASE,SNPCTRL,PHE);



% CREATE A LIST OF CASE AND CTRL IDS
CASEID = IDVX.SRR(IDVX.AD==1 & IDVX.NV>0);
CTRLID = IDVX.SRR(IDVX.AD==0 & IDVX.NV>0);





clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX
end







%% COUNT NUMBER OF CASE/CTRL IDs AT EACH VARIANT SITE
disp('COUNTING NUMBER OF CASE/CTRL IDs AT EACH VARIANT SITE')

try disp(ADMX.CASEALTS(1:5)) % IF ADMX.CASEALTS IS MISSING, DO...
catch


% COUNT THE NUMBER OF VARIANTS FOR THOSE IN CASEID CTRLID LISTS
[CASEnv,CTRLnv] = getALT(SNPCASE,SNPCTRL,CASEID,CTRLID);


ADMX.CASEREFS = numel(CASEID)-CASEnv;
ADMX.CTRLREFS = numel(CTRLID)-CTRLnv;

ADMX.CASEALTS = CASEnv;
ADMX.CTRLALTS = CTRLnv;





clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX
end





%% FILTER OUT UNWANTED VARIANTS
disp('FILTERING OUT UNWANTED VARIANTS')



% FILTER VARIANTS BASED ON EFFECT TYPE
%   [SYN MIS STG STL SPA SPD INT NCE UTR CUK]
L = [ 1   1   1   1   1   1   1   1   1   0];

[KEEP] = keepEFFECT(ADMX,L);

ADMX    = ADMX( KEEP , : );
SNPCASE = SNPCASE(KEEP);
SNPCTRL = SNPCTRL(KEEP);
ADMX.VID = ( 1:size(ADMX,1) )';



% FILTER VARIANTS BASED ON LOW ALT COUNTS
PASS = (ADMX.CASEALTS > 2 & ADMX.CTRLALTS > 2) & ...
       ((ADMX.CASEALTS + ADMX.CTRLALTS)>30);

ADMX    = ADMX( PASS , :);
SNPCASE = SNPCASE(PASS);
SNPCTRL = SNPCTRL(PASS);
ADMX.VID = (1:size(ADMX,1))';



clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX






%% COMPUTE FISHER'S EXACT TEST STATISTIC
disp('COMPUTING FISHERS EXACT TEST STATISTIC')



try disp([ADMX.FISHPS(1:5,:) ADMX.FISHORS(1:5,:)])
catch



[FISHP, FISHOR] = getFISH(ADMX.CASEREFS, ADMX.CASEALTS, ADMX.CTRLREFS, ADMX.CTRLALTS,'parfor');

ADMX.FISHPS  = FISHP;
ADMX.FISHORS = FISHOR;


clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX
end





%% START ESTABLISHING VARIANT SET FOR CROSSCORRELATION TABLE INCLUSION
disp('ESTABLISHING VARIANT SET FOR CROSSCORRELATION TABLE INCLUSION')

APOEpos = [45411941, 45409167, 45411110];
GENEpos = [20 47253150; 17 64783081];

% APOE:  19,45411941
% APOE:  19,45409167
% APOE:  19,45411110
% PREX1: 20,47253150
% PRKCA: 17,64783081

PASSapoe = ADMX.CHR == 19 & ...
  (ADMX.POS == APOEpos(1) | ADMX.POS == APOEpos(2) | ADMX.POS == APOEpos(3) );


PASSmisc = (((ADMX.CASEALTS + ADMX.CTRLALTS)>30) ...
          & ((ADMX.CASEALTS + ADMX.CTRLALTS)<(ADMX.CASEREFS + ADMX.CTRLREFS))) ...
          & (ADMX.FISHPS < .0015) & (ADMX.CASEALTS > 1 & ADMX.CTRLALTS > 1);


incrows = (PASSapoe+PASSmisc) > 0;

ASYMX   = ADMX( incrows , :);
ASYCASE = SNPCASE(incrows);
ASYCTRL = SNPCTRL(incrows);
ASYMX.VID = (1:size(ASYMX,1))';



clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX ...
ASYMX ASYCASE ASYCTRL



%% ONLY KEEP ONE INSTANCE PER GENE (THE ONE WITH LOWEST P-VAL)

% SORT DATASET FROM LOW TO HIGH FISHERS P-VALUE
% UNIQUE() WILL RETURN INDEX OF VARIANT WITH LOWEST P
%
%   [C,ia,ic] = unique(A)
%   C = A(ia) and A = C(ic).



% SORT VARIANTS BY FISHERS P-VALUE
[J , I] = sortrows(ASYMX.FISHPS);
ASYMX   = ASYMX(I,:);
ASYCASE = ASYCASE(I);
ASYCTRL = ASYCTRL(I);
ASYMX.VID = (1:size(ASYMX,1))';



% ONLY INCLUDE FIRST VARIANT FOUND FOR EACH GENE
[C,ia,ic] = unique(string(ASYMX.GENE));

ASYMX   = ASYMX(  ia , :);
ASYCASE = ASYCASE(ia);
ASYCTRL = ASYCTRL(ia);
ASYMX.VID = (1:size(ASYMX,1))';


% CLEAN UP WORKSPACE
clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX ...
ASYMX ASYCASE ASYCTRL








%% REINSERT THE TWO APOE SITES THAT WERE REMOVED
% IN ANY OF THE DATASETS, IT WILL ALMOST SURELY BE
% SITE #2 (CHR19:45409167) AND #3 (CHR19:45411110) 
% THAT WERE REMOVED, SINCE SITE #1 (CHR19:45411941)
% TYPICALLY HAS A P-VALUE ~1E-276


APOEpos = [45411941, 45409167, 45411110];
PASSapoe = ADMX.CHR == 19 & (ADMX.POS == APOEpos(2) | ADMX.POS == APOEpos(3));

T1 = ADMX( PASSapoe , :);
T2 = SNPCASE( PASSapoe );
T3 = SNPCTRL( PASSapoe );

ASYMX   = [ASYMX   ; T1];
ASYCASE = [ASYCASE ; T2];
ASYCTRL = [ASYCTRL ; T3];


[J , I] = sortrows(ASYMX.FISHPS);
ASYMX   = ASYMX(I,:);
ASYCASE = ASYCASE(I);
ASYCTRL = ASYCTRL(I);
ASYMX.VID = (1:size(ASYMX,1))';


% CLEAN UP WORKSPACE
clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX ...
ASYMX ASYCASE ASYCTRL






%% MAKE  NN-SHAPED  VARIANT MATRIX
disp('MAKING NN-SHAPED VARIANT MATRIX')


[ADNN, caMX, coMX] = makeNNMX(ASYMX,ASYCASE,ASYCTRL,CASEID,CTRLID);




clearvars -except ADMX SNPCASE SNPCTRL PHE CASEID CTRLID IDVX ...
ASYMX ASYCASE ASYCTRL ADNN caMX coMX



disp('ALL DONE. BACK TO YOU!')
%%
end