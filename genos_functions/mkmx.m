function [PVMX, VMX, YVEC, YDUM] = mkmx(LX,CA,CO,UC,PHE,varargin)


% keyboard

SRR = PHE.SRR;

vMX  = zeros( size(SRR,1) , size(CA,1) );


for nn = 1:size(CA,1)

    CASES = CA{nn};
    CTRLS = CO{nn};

    UNCAS = [UC{nn} (-ones(numel(UC{nn}),1))];
    
    CACOUN = [CASES; CTRLS; UNCAS];
    
    if any(any(CACOUN))
        CACOSRR = CACOUN(:,1);
        CACOHH  = CACOUN(:,2);
        [~,Aj] = ismember(SRR , CACOSRR );
        Af = Aj(Aj>0);
        % UNCALL:-1  HOMREF:0  HETALT:1  HOMALT:2  
        vMX(Aj>0,nn) = CACOHH(Af); 
    end

end


vMX = vMX + 20;   % UNCALL:19  HOMREF:20  HETALT:21  HOMALT:22



if nargin > 5
    v = varargin{end};
    vMX(vMX==19) = v(2);  % UNCALL
    vMX(vMX==20) = v(1);  % REF/REF
    vMX(vMX==21) = v(3);  % REF/ALT
    vMX(vMX==22) = v(4);  % ALT/ALT
else % DEFAULT
    vMX(vMX==19) =  0;    % UNCALL
    vMX(vMX==20) = -1;    % REF/REF
    vMX(vMX==21) =  2;    % REF/ALT
    vMX(vMX==22) =  3;    % ALT/ALT
end





PVMX = [zeros(size(vMX,1),9) vMX];
PVMX(: , 1)  =  PHE.SRR;        % COL1: ID
PVMX(: , 2)  =  PHE.AD;         % COL2: AD
PVMX(: , 3)  =  PHE.COHORTNUM;  % COL3: COHORT
PVMX(: , 4)  =  PHE.AGE;        % COL4: AGE
PVMX(: , 5)  =  PHE.APOE;       % COL5: APOE
PVMX(: , 6)  =  PHE.SEX;        % COL7: SEX
PVMX(: , 7)  =  PHE.BRAAK;      % COL6: BRAAK
PVMX(: , 8)  =  PHE.BRAAK;      % COL6: BRAAK
PVMX(: , 9)  =  PHE.BRAAK;      % COL6: BRAAK




% BRAGE = AGE - BRAD
%------------------------------------------------
% COLS:  PVMX( 1 , 2, 3 , 4 ,  5 , 6 ,  7  ,  8  ,  9    ...)
% START: PVMX(SRR,AD,COH,AGE,APOE,SEX,BRAAK,BRAAK,BRAAK.....)
% END:   PVMX(SRR,AD,COH,AGE,APOE,BRAD,BRAAK,AGEz,BRAGEz....)
% [BRAX] = bragepvmv(PVTR);

% GET BRAAK & AGE (BRAGE) WEIGHTS
PVMX = bragepvmv(PVMX);




% MAKE ANOTHER MATRIX THAT IS ONLY THE VARIANT COLUMNS (REMOVE PHE COLUMNS)
VMX = PVMX(:,10:end);




% CREATE AN Nx1 LABEL ARRAY
% YVEC(:,1)==1  :CASE
% YVEC(:,1)==0  :CTRL

YVEC = PVMX(:,2);



% CREATE AN Nx2 LABEL MATRIX
% YDUM(:,1)==1  :CASE
% YDUM(:,2)==1  :CTRL

YDUM = (dummyvar( (YVEC~=1)+1 ));

%%
end
% TR_DL = dummyvar(  categorical( PVMX(:,2) )  );
% TR_DL = dummyvar(  categorical(  (PVMX(:,2)==1) == 0 )  );




