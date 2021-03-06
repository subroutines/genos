function PVMX = mlmx(CA,CO,UC,PHE)

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


vMX = vMX + 1;     % UNCALL:0  HOMREF:1  HETALT:2  HOMALT:3
vMX(vMX==1) = -1;  % UNCALL:0  HOMREF:-1  HETALT:2  HOMALT:3
vMX(vMX==3) =  5;  % UNCALL:0  HOMREF:-1  HETALT:2  HOMALT:5

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

end