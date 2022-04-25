% SCRIPT "VALIDATE"
%
% Use to validate tornado results against outher sources:
% Select comparison with variable typeofrun
%
%   #1  LIFTSLOPE VALIDATION 
%   #2  TAPER VALIDATION, Spanload check using monoplane equation,
%   #3  Paneling validation, testing the different paneling schemes
%   #4  NACA TN 1422 Validation Case 
%   #5  Test case, vo validation
%   #6  NASA TN D-926
%   #7  NACA RM R6K15
%   #8  NACA0001 Airfoil comparison, XFOIL
%   #9  Dihedral Validation
%   #10 Dihedral Validation TN1732
%   #11 Dihedral Validation TN1668 #1
%   #12 Dihedral Validation TN1668 #2
%   #13 Dihedral Validation TN1668 #3.1
%   #14 Dihedral Validation TN1668 #3.2
%   #15 Dihedral Validation TN1668 #3.3
%   #16 NACA0008 FLAP Airfoil comparison
%   #17 NASA TN4888 Propeller validation, figure 11b
%
%   Set output=0 in the file config.m for a less chatty output.
%
%   Version history
%   Spånga, 2021-09-19:   Updated to MATLAB R2020, TM  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
typeofrun=17;




settings=config('startup');

switch typeofrun
%% LIFTSLOPE VALIDATION


case 0
    results=[];
    figure(1)    
    cd(settings.acdir)
        load('ellipse');
        
        
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
        
        
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    state.alpha=1*pi/180;
    quest=1;                %Simple state solution, could be something else
                            %but then you'll have to change below too
    JID='batchjob';             

    geo.nx=geo.nx*2;

    nooftests=40;
    %%%%%%%%%%

    AR1=1:0.25:20;
    const=2*pi*ones(size(AR1));
    h=plot(AR1,const);
    set(h,'Linewidth',2)
    hold on

    CLA=2*pi./(1+2./AR1);
    h=plot(AR1,CLA); hold on;
    set(h,'LineStyle','--','Linewidth',2)

    AR2=0:0.25:3;
    CLA2=pi/2*AR2;
    h=plot(AR2,CLA2);
    set(h,'LineStyle','-.','Linewidth',2)
    %%%%%%%%%%%


    B=geo.b*0.1;

    for i=1:nooftests
         geo.b=B*i;
         [lattice,ref]=fLattice_setup2(geo,state,0);

         AR(i)=ref.b_ref^2/ref.S_ref;
         solverloop5(results,quest,JID,lattice,state,geo,ref);

            cd(settings.odir)
                load batchjob-Cx;
            cd(settings.hdir)

        outdata1(i,1)=results.CL;
        outdata2(i,2)=results.CD;                %Save your outdata here

        CLa(i)=outdata1(i,1)/(pi/180);

        drawnow
    end

    plot(AR,CLa,'O');
    title('Lift slope of an elliptic wing for different aspect ratios')
    xlabel('Aspect Ratio, AR, [-]')
    ylabel('Lift Slope, CL_\alpha')
    legend('2D maximum','Lifting Line','Jones small AR','Tornado','Location','SouthEast')




    %% TAPER VALIDATION
    %Spanload check using monoplane equation,
case 1
    

figure(2)
    for K=1:4
    Taper=[1 0.6 0.4 0.1];
    T=Taper(K);


    alpha=4;
    npos=100;
    Cr=1;
    Ct=T*Cr;
    B=6.3/2;
    AR=2*2*B/(Cr+Ct);
    phi=(pi/2/npos:pi/2/npos:pi/2);
    b=-cos(phi)*B;
    t=(Cr-(-b./B*(Cr-Ct)))./Cr;
    c=Cr*t;
    a0=2*pi;

    mu=c*a0./(2*AR*Cr*(1+T));
    %monoplane equation
    rhs=(mu*((alpha)*pi/180).*sin(phi))';

    for i=1:npos
        for j=1:npos
            n=(2*j-1);     
            sn2(i,j)=sin(n*phi(i))*(n*mu(i)+sin(phi(i)));
        end
    end
    A=sn2\rhs;
    for i=1:npos
        cld(i)=2*(1+T)/(pi*A(1))    *  Cr/c(i)  *     sum(A'.*sin((1:2:(npos*2-1))*phi(i)));
    end

    plot(cos(phi),cld)
    drawnow
    hold on



    %and then the tornado computation
    cd(settings.acdir)
        load('spantest');
        
                if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
        
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    geo.ny=10;
    geo.nx=3;
    geo.b=B;
    geo.meshtype=4;
    geo.T=T;

    quest=1;                %Simple state solution, could be something else
    results=[];             %but then you'll have to change below too
    JID='batchjob';             
    [lattice,ref]=fLattice_setup2(geo,state,2);
    solverloop5(results,quest,JID,lattice,state,geo,ref);

    cd(settings.odir)
      load batchjob-Cx;
    cd(settings.hdir)

    lcl=results.CL_local./results.CL;
    lsp=results.ystation/geo.b;

    lemma=size(lsp,1)/2;
    plot(lsp((lemma+1):1:end),lcl((lemma+1):1:end),'k*')


    xlabel('Spanstation, y/S, [-]')
    ylabel('Normalized lift, C_l/C_L, [-]')
    end
    legend('Monoplane equation','Tornado','location','south')
    text(0.3,0.3,'Taper = 1, 0.6, 0.4, 0.1 respectively')

%% DIHEDRAL VALIDATION

%% C172 VALIDATION
case 2    %Cant get this to match properly just yet.
    figure(3)
    % Data from L.L. Leisher et al, Stability derivatives of Cessna aircraft, Cessna
    % Aircraft Company, 1957.
    CL=0.386;
    CD=0.042;
    CL_a=4.41;
    CD_a=0.182;
    Cm_a=-0.409;
    Cm_de=-1.099;
    CY_b=-0.35;
    Cl_b=0.103;         %Change sign due to different convensions
    Cn_b=-0.0583;       %Change sign due to different convensions
    CY_p=0.0925;        %Change sign due to different convensions
    Cl_p=-0.483;
    Cn_p=-0.035;
    CY_r=-0.175;        %Change sign due to different convensions
    Cl_r=-0.1;          %Change sign due to different convensions
    Cn_r=-0.086;        %Change sign due to different convensions
    Cl_da=0.229;
    Cn_da=0.027;
    Cn_dr=-0.0539;
    %%%%%%%%%%%%%





    cd(settings.acdir)
        load('test2');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('cessnastate');
    cd(settings.hdir)

    state.AS=state.AS*2;
    results=[];


    quest=1;                %Simple state solution, could be something else
                            %but then you'll have to change below too
    JID='batchjob';             

    geo.nx=geo.nx;
    geo.ny=geo.ny;

     [lattice,ref]=fLattice_setup2(geo,state,1);
     solverloop5(results,quest,JID,lattice,state,geo,ref);

       cd(settings.odir)
            load batchjob-Cx;
       cd(settings.hdir)

    %quest=8;                %Central Differernce 
    %solverloop5(results,quest,JID,lattice,state,geo,ref);

    %cd(settings.odir)
    %       load batchjob-Cxx_diff;
    %cd(settings.hdir)   

    A=[ CL   results.CL
        CD   results.CD
        CL_a    results.CL_a
        CD_a   results.CD_a
        Cm_a  results.Cm_a
        Cm_de  results.Cm_d(3)
        CY_b   results.CY_b
        Cl_b  results.Cl_b
        Cn_b  results.Cn_b
        CY_p results.CY_P
        Cl_p  results.Cl_P
        Cn_p  results.Cn_P
        CY_r   results.CY_R
        Cl_r    results.Cl_R
        Cn_r   results.Cn_R
        Cl_da   results.Cl_d(2)
        Cn_da   results.Cn_d(2)
        Cn_dr results.Cn_d(4)];

    subplot(2,1,1)    
    h=bar(A,0.75,'grouped');
    h2=gca;
    set(h2,'XTick',1:1:18);
    set(h2,'XTickLabel',{'CL','CD','CL_a','CD_a','Cm_a','Cm_de','CY_b','Cl_b'...
        ,'Cn_b','CY_P','Cl_P','Cn_P','CY_R','Cl_R','Cn_R','Cl_da','Cn_da','Cn_dr'});

    subplot(2,1,2)

    B=diff(abs(A)')';
    err=B./A(:,1);
    bar(err);
    h2=gca;
    set(h2,'XTick',1:1:18);
    set(h2,'XTickLabel',{'CL','CD','CL_a','CD_a','Cm_a','Cm_de','CY_b','Cl_b'...
        ,'Cn_b','CY_P','Cl_P','Cn_P','CY_R','Cl_R','Cn_R','Cl_da','Cn_da','Cn_dr'});




%% Paneling validation, testing the different paneling schemes
case 3

for i=1:4
    cd(settings.acdir)
        load('spantest');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
        
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    geo.ny=10;
    geo.nx=5;
    geo.b=3;
    geo.meshtype=i;         %<----- set paneling
    geo.T=0.6;

    quest=1;                %Simple state solution, could be something else
    results=[];             %but then you'll have to change below too
    JID='batchjob';             
    [lattice,ref]=fLattice_setup2(geo,state,0);
    solverloop5(results,quest,JID,lattice,state,geo,ref);
    cd(settings.odir)
      load batchjob-Cx;
    cd(settings.hdir)

    lcl=results.CL_local./results.CL;
    lsp=results.ystation/geo.b;

    RXZ={'kx-', 'r*--', 'gd-.','m+:'};;

    lemma=size(lsp,1)/2;
    figure(4)
    %plot(lsp((lemma+1):1:end),lcl((lemma+1):1:end),RXZ(i))

    h=plot(lsp,lcl,cell2mat(RXZ(i)));
    set(h,'Linewidth',2)
    title('Spanload with different paneling schemes.')
    xlabel('Spanstation, y/S, [-]')
    ylabel('Normalized lift, C_l/C_L, [-]')    
       hold on

       %geometryplot(lattice,geo,ref);
       hold on
    end  
    legend('Linear','Half cosine in y','Cosine in x, half cosine in y','Cosine in x, cosine in y','Location','South')



%% NACA TN 1422 Validation Case

case 4

    %Experimental Data
    %ex.alpha=[-3 -2 -0.8 0.1 1.3 2.3 3.6 4.5 5.5 6.5 7.6 8.4 9.8 10.8 11.5 12 12.4 13 13.5 14 14.5 15 15.6 15.7];    
    %ex.CL=[-0.19 -0.09 0 0.1 0.19 0.28 0.37 0.46 0.55 0.63 0.74 0.82 0.91 1.01 1.05 1.1 1.13 1.19 1.23 1.26 1.31 1.34 1.35 1.03];    
    %ex.CD=0.001*[8 6 5 5 6 8 10 15 19 24 28 35 42 50 54 58 62 66 71 76 81 85 90 118]; 
    %ex.CD0=0.001*[6.2 6 5 4.5 4.3 4.5 5.5 6.8 7.5 8.2 8.8 10.1 12 13]

    ex.CD=[40 35 30 28 30 42 58 80 100 130 158 194 230 276 292 320 348 362 389 420 448 470 500 645]*0.1/550;
    ex.CD0=[175 158 140 123 120 123 140 190 210 230 245 280 315 345].*0.016/440;
    ex.CL=[10 60 112 164 218 270 320 364 413 460 520 565 618 668 688 712 732 760 785 806 830 850 854 680]*1.4/770-0.2;
    ex.alpha=[30 60 85 115 145 175 206 233 262 291 320 350 380 410 425 440 453 468 484 500 510 525 540 540]*20/553-4;


    ex.y=[0 1 2 3 4 5 6 6.5 7 7.5 8 8.5 9 9.5]*0.1;
    ex.Cl=[1.3 1.35 1.38 1.4 1.42 1.43 1.42 1.41 1.39 1.37 1.34 1.3 1.2 1.03];

    x=ex.CL(8:end);
    ex.extrap.CD0 = 0.0084*x.^2 - 0.0023*x + 0.0062;


    ex.CD0comp=[ex.CD0(1:8) ex.extrap.CD0(2:end)];

    cd(settings.acdir)
        load('NACATN1422');
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)


    geo.nx=10;
    geo.ny=10;
    j=0;
    R=[];
    stallCl=[];

    for i=1:21;   %Angle of attack
    alpha=(-3:1:20)*pi/(180);
    alpha(19)=14.9*pi/180;          %Stall angle    
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
        results=trefftz5(results,state,geo,lattice,ref);

        R.alpha(i)=state.alpha;
        R.CL(i)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;
        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;
        R.TDC(i)=results.Trefftz_drag_Coeff;

        %figure(6)
        %plot(results.ystation,results.CL_local)
        %hold on
        indx=find(results.CL_local>1.44);

        if isempty(indx)==0;
            disp('STALL ONSET')
            j=j+1;

            %plot(results.ystation(indx),results.CL_local(indx),'r*')
            stalledalpha(j)=state.alpha;
            stallCl(j,:)=results.CL_local;
            stallCL(j)=results.CL;
            break
        end

    end

    figure(6)
    h1=plot(results.ystation./(0.5*ref.b_ref),stallCl(1,:))
    hold on
    h2=plot(results.ystation(indx)./(0.5*ref.b_ref),stallCl(1,indx) ,'r*')
    h4=plot(ex.y,ex.Cl,'O');
    h3=plot([0.2 0.6],[1.44 1.44],'r');
    set(h1,'Linewidth',2);
    set(h2,'Linewidth',2);
    set(h3,'Linewidth',2);
    set(h3,'Linewidth',2);
    title('Lift distribution, NACA TN 1422, first case.')
    xlabel('Spanstation, 2y/b, [-]')
    ylabel('Local lift cofficient, C_l, [-]')
    legend('Tornado','Stalled panels','Experimental distribution','Experimental stall position')
    axis([0 1 0.6 1.6]);
    grid 


    CLa=sum(diff(R.CL))/(size(R.CL,2)-1)

    A=[ones(size(R.CL))' R.CL'];
    aLO=A\R.alpha';
    Alpha_LO=aLO(1)*180/pi

    STL=min(stalledalpha)*180/pi;
    figure(5)
    h=plot(R.alpha*180/pi,R.CL);
    hold on
    h2=plot(ex.alpha,ex.CL,'O');
    h3=plot([STL STL],[0 1.5],'r:');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    set(h3,'Linewidth',2)
    title('Lift curve, NACA TN 1422, first case.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment','Tornado stall onset predicition',2)
    grid 

    figure(7)

    h1=plot(ex.CD-ex.CD0comp,ex.CL,'O');
    hold on
    h2=plot(R.CD,R.CL);
    h3=plot(R.TDC,R.CL,'r');
    set(h1,'Linewidth',2);
    set(h2,'Linewidth',2);
    set(h3,'Linewidth',2);

    title('Polar, NACA TN 1422, first case.')
    xlabel('Induced Drag Cofficient, C_Di, [-]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Experiment','Tornado','Tornado Trefftz corrected',4)
    grid



%% Test case, vo validation
case 5
    
    cd(settings.acdir)
        load('NACATN1422');
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)



    j=0;
    R=[];
    stallCl=[];

    imax=25;
    for i=1:imax;
        i
    alpha=10.8282*pi/180;

    geo.nx=10;
    geo.ny=i;

    geo.b=90;
    geo.meshtype=2;

    state.AS=60;
    state.pgcorr=1;


    state.alpha=alpha;

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        results=trefftz5(results,state,geo,lattice,ref);
        R.TDC(i)=results.Trefftz_drag_Coeff;



        %R.alpha(i)=state.alpha;
        R.CL(i)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;



    end
    figure(8)
    h=plot([1 geo.nx*imax],[0.0376 0.0376],'g');
    set(h,'Linewidth',2);
    hold on


    h=plot(geo.nx*(1:imax),R.TDC,'r');
    set(h,'Linewidth',2);
    h=plot(geo.nx*(1:imax),R.CD,'b');
    set(h,'Linewidth',2);

    xlabel('Number of panels.')
    ylabel('Induced drag coefficient, CD_i')
    title('Naca TN1422, case #1, 10 degree AoA')
    axis([0 geo.nx*imax 0 max(R.TDC)])
    legend('Experimantal','Trefftz','Tornado')
    grid




%% NASA TN D-926
case 6
    disp('NASA TN D-926')


    %ex.alpha=[-10 -6 -4 -2 0 2 4 6 8 10 12 14 16 18];
    %ex.CL=[2 14 20 26 33 41 48.5 56 63 70 78.5 87 93 100]*1/100;
    %ex.CD=[3 3.5 4 5 6.1 7.5 9.5 11.5 14 16.5 19.9 24 28 39]*1/100;

    ex.alpha=[-10 -8 -6 -3.8 -1.8 0.4 2.5 4.6 6.7 8.8 10.8 12.9 14.9 17];
    ex.CL=[8 18 31 44 60 73 85 98 112 125 138 144 149 149]*1/100;
    ex.CD=[2.4 2.5 2.6 3 4 5.6 7.5 9 11.5 14 17 20 24 30]*1/100;


    cd(settings.acdir)
        load('NASATND926');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
        
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    j=0;
    geo.nx=[10];
    geo.ny=[20];
    geo.b=2;

    for i=1:20;   %Angle of attack
    alpha=(-12:2:20)*pi/(180);
    alpha(19)=14.9*pi/180;          %Stall angle    
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        results=trefftz5(results,state,geo,lattice,ref);

        R.alpha(i)=state.alpha;
        R.CL(i)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;
        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;
        R.TDC(i)=results.Trefftz_drag_Coeff;

        %figure(6)
        %plot(results.ystation,results.CL_local)
        %hold on
        indx=find(results.CL_local>1.42);

        if isempty(indx)==0;
            disp('STALL ONSET')
            j=j+1;

            %plot(results.ystation(indx),results.CL_local(indx),'r*')
            stalledalpha(j)=state.alpha;
            stallCl(j,:)=results.CL_local;
            stallCL(j)=results.CL;
            break
        end

    end
    STL=min(stalledalpha)*180/pi;

    figure(9)
    h=plot(R.alpha*180/pi,R.CL);
    hold on
    h2=plot(ex.alpha,ex.CL,'O');
    h3=plot([STL STL],[0 1.5],'r:');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    set(h3,'Linewidth',2)
    title('Lift curve, NACA TND 926, AR=4.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment','Tornado stall onset predicition')
    grid 

    figure(10)
    experimentalCD0=0.024;
    h1=plot(ex.CD-experimentalCD0,ex.CL,'O');
    hold on
    h2=plot(R.CD,R.CL);
    h3=plot(R.TDC,R.CL,'r-.');
    set(h1,'Linewidth',2);
    set(h2,'Linewidth',2);
    set(h3,'Linewidth',2);

    title('Polar, NACA TND 926, AR=4.')
    xlabel('Induced Drag Cofficient, C_Di, [-]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Experiment','Tornado','Trefftz plane')
    grid



%% NACA RM R6K15
case 7
    disp('NACA RM R6K15')

    cd(settings.acdir)
        load('NACATMR6K15');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
        
        
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    S1=[  -3.2975   -0.1247    0.0233   -0.0109
        0.1434    0.0260    0.0233         0
        2.5806    0.1356    0.0215    0.0181
        4.9462    0.2486    0.0286    0.0159
        9.3190    0.4507    0.0483    0.0210
       13.0466    0.6356    0.0769    0.0196
       16.1290    0.7521    0.1342   -0.0152
       18.9247    0.8925    0.1932   -0.0051
       21.3620    0.9678    0.2379    0.0029
       23.7276    1.0363    0.2987    0.0065
       25.8781    1.0705    0.4007    0.0239
       29.4624    1.0877    0.5403    0.0355
       31.5412    1.0877    0.6100    0.0500];

    S2=[ -2.9243   -0.1312    0.0311    0.0053
        0.2463    0.0561    0.0260    0.0032
        3.4170    0.2467    0.0260   -0.0044
        6.3808    0.4307    0.0363   -0.0100
        9.6204    0.6245    0.0501   -0.0170
       12.6532    0.8085    0.0725   -0.0233
       16.0306    0.9991    0.1225   -0.0219
       18.5809    1.1010    0.1811   -0.0086
       20.8555    1.1634    0.2241   -0.0024
       22.5786    1.1831    0.3069   -0.0003
       24.9222    1.0681    0.3999   -0.0017
       28.9199    0.9695    0.4981    0.0018];

    S3=[   -1.9679   -0.0707    0.0391   -0.0266
        0.1111    0.0447    0.0340   -0.0286
        2.1900    0.1940    0.0323   -0.0296
        4.2019    0.3331    0.0391   -0.0316
        6.2808    0.4723    0.0441   -0.0327
        8.3598    0.6012    0.0543   -0.0332
       10.3046    0.7403    0.0695   -0.0337
       12.3836    0.8760    0.0847   -0.0337
       14.3954    1.0220    0.1049   -0.0337
       15.6026    1.0898    0.1167   -0.0332
       16.6085    1.1475    0.1252   -0.0322
       17.6815    1.2086    0.1404   -0.0322
       18.5533    1.2697    0.1522   -0.0266
       19.6263    1.3240    0.1691   -0.0256
       20.7664    1.3715    0.1775   -0.0286
       21.7053    1.2595    0.2451    0.0053];

    S4=[-3.3492   -0.1708    0.0279    0.0007
       -0.1154    0.0378    0.0245    0.0095
        2.1078    0.1824    0.0245    0.0169
        4.2637    0.3237    0.0296    0.0223
        6.4869    0.4718    0.0363    0.0284
        8.5080    0.6097    0.0481    0.0324
       10.5964    0.7376    0.0565    0.0364
       12.6849    0.8688    0.0768    0.0412
       14.7734    1.0000    0.0953    0.0432
       15.7165    1.0437    0.1037    0.0438
       16.7271    1.1110    0.1172    0.0452
       17.7376    1.1581    0.1290    0.0465
       18.7482    1.2220    0.1391    0.0479
       20.0956    1.2859    0.1559    0.0479
       21.1735    1.2355    0.2233    0.0129
       22.6556    1.1884    0.2873    0.0061];

    S5=[-3.0427   -0.1484    0.0250   -0.0020
        0.1148    0.0347    0.0194    0.0067
        2.1708    0.1460    0.0194    0.0082
        3.1254    0.2071    0.0194    0.0119
        4.4472    0.2753    0.0250    0.0155
        6.2829    0.3794    0.0286    0.0199
        8.5592    0.5087    0.0379    0.0243
        9.4404    0.5518    0.0415    0.0272
       12.4510    0.7062    0.0636    0.0382
       15.5350    0.8786    0.0913    0.0514
       18.7659    1.0581    0.1318    0.0806
       20.7485    1.1263    0.2129    0.0763
       22.7311    1.1694    0.2866    0.0587
       24.6403    1.2053    0.3897    0.0353
       26.6229    1.2305    0.4966    0.0214
       28.6789    1.2018    0.5316    0.0294
       29.7803    1.1623    0.5518    0.0492];



    j=0;
    geo.nx=[5];
    geo.ny=[10];
    %geo.b=2;
        T=[0.38 0.4 0.55 0.44 0.42];
        b=[32.38 36.39 30.53 36.06 33.56]*0.5*0.3;
        c=[15.4 11.34 8.71 10.59 13.34]*0.3;
        SW=[-45 -30 0 30 45]*pi/180;
        refp=[-2.9 -1.5 2.27 7.25 10.71]*0.3;
    for j=1:5


        geo.ref_point=[refp(j) 0 0];
        geo.b=b(j);
        geo.T=T(j);
        geo.c=c(j);
        geo.SW=SW(j);


        wingx(j,:)=[0 0.25*geo.c+geo.b*tan(geo.SW)-0.25*geo.T*geo.c 0.25*geo.c+geo.b*tan(geo.SW)+0.75*geo.T*geo.c geo.c]./geo.c;
        wingy(j,:)=[0 geo.b geo.b 0]./geo.c;
        wingz(j,:)=[0 0 0 0]./geo.c;


    figure(20)
    subplot(3,2,1)
    plot3(wingx(j,:)+1.2*j,wingy(j,:),wingz(j,:),'k');
    hold on
    plot3(wingx(j,:)+1.2*j,-wingy(j,:),wingz(j,:),'k');
    axis equal
    axis off

    for i=1:16;   %Angle of attack
    alpha=(-4:2:26)*pi/(180);   
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
            %if i==1
            %    geometryplot(lattice,geo,ref);
            %end
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
      %  results=trefftz5(results,state,geo,lattice,ref);

        R.alpha(j,i)=state.alpha;
        R.CL(j,i)=results.CL;
        R.CD(j,i)=results.CD;
        R.Cm(j,i)=results.Cm;
    %    R.CLL(j,i,:)=results.CL_local;
    %    R.YS(j,i,:)=results.ystation;
    %    R.TDC(j,i)=results.Trefftz_drag_Coeff;

    end
    end


    a(1)=sum(diff(S1(1:6,2))./(diff(S1(1:6,1))*pi/180))/5;
    a(2)=sum(diff(S2(1:6,2))./(diff(S2(1:6,1))*pi/180))/5;
    a(3)=sum(diff(S3(1:6,2))./(diff(S3(1:6,1))*pi/180))/5;
    a(4)=sum(diff(S4(1:6,2))./(diff(S4(1:6,1))*pi/180))/5;
    a(5)=sum(diff(S5(1:6,2))./(diff(S5(1:6,1))*pi/180))/5;

    b(1)=sum(diff(R.CL(1,1:6))./(diff(R.alpha(1,1:6))))/5;
    b(2)=sum(diff(R.CL(2,1:6))./(diff(R.alpha(2,1:6))))/5;
    b(3)=sum(diff(R.CL(3,1:6))./(diff(R.alpha(3,1:6))))/5;
    b(4)=sum(diff(R.CL(4,1:6))./(diff(R.alpha(4,1:6))))/5;
    b(5)=sum(diff(R.CL(5,1:6))./(diff(R.alpha(5,1:6))))/5;

    sweep=[-45 -30 0 30 45];
    rerr=(b-a)./a;


    figure(17)
    subplot(2,1,1)
    bar( [a' b'], 'group')
     xlabel('Wing Sweep, \Lambda, [deg]')
     ylabel('Liftslope, a, [1/rad]')
     legend('Experiments','Tornado','Location','South')
     title('Comparison between experimental and numerical linear liftslope.')

    subplot(2,1,2)
    bar(rerr)
     xlabel('Wing Sweep, \Lambda, [deg]')
     ylabel('Liftslope relative error, err, [-]')


    figure(12)
    h=plot(R.alpha(1,:)*180/pi,R.CL(1,:));
    hold on
    h2=plot(S1(:,1),S1(:,2),'O');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    title('Lift curve, NACA TM R6K15,  Sweep=-45.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment')
    grid 

    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    axis off

    %--------------------
    figure(13)
    h=plot(R.alpha(2,:)*180/pi,R.CL(2,:));
    hold on
    h2=plot(S2(:,1),S2(:,2),'O');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    title('Lift curve, NACA TM R6K15,  Sweep=-30.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment')
    grid 

    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(2,:),-wingx(2,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(2,:),-wingx(2,:),'k');
    set(h,'Linewidth',3)
    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    axis off

    %--------------------
    figure(14)
    h=plot(R.alpha(3,:)*180/pi,R.CL(3,:));
    hold on
    h2=plot(S3(:,1),S3(:,2),'O');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    title('Lift curve, NACA TM R6K15,  Sweep=0.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment')
    grid 

    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(3,:),-wingx(3,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(3,:),-wingx(3,:),'k');
    set(h,'Linewidth',3)
    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    axis off
    %--------------------
    figure(15)
    h=plot(R.alpha(4,:)*180/pi,R.CL(4,:));
    hold on
    h2=plot(S4(:,1),S4(:,2),'O');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    title('Lift curve, NACA TM R6K15, Sweep=30.')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment')
    grid 

    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(4,:),-wingx(4,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(4,:),-wingx(4,:),'k');
    set(h,'Linewidth',3)
    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    axis off



    %--------------------
    figure(16)
    h=plot(R.alpha(5,:)*180/pi,R.CL(5,:));
    hold on
    h2=plot(S5(:,1),S5(:,2),'O');
    set(h,'Linewidth',2)
    set(h2,'Linewidth',2)
    title('Lift curve, NACA TM R6K15, Sweep=45')
    xlabel('Angle of Attack, alpha, [deg]')
    ylabel('Lift Cofficient, C_L, [-]')
    legend('Tornado','Experiment')
    grid


    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(5,:),-wingx(5,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(5,:),-wingx(5,:),'k');
    set(h,'Linewidth',3)
    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    axis off
    %--------------------




case 8
    disp('NACA0001 Airfoil comparison')

    cd(settings.acdir)
        load('NACA0010');
                if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)


    xfoilcp5deg=[                   %NACA 0001 @ 5 deg, inviscous
        0.0033    4.2785
        0.0089    3.9581
        0.0210    2.3463
        0.0358    1.8600
        0.0508    1.5428
        0.0657    1.3479
        0.0807    1.2068
        0.0957    1.0991
        0.1106    1.0126
        0.1256    0.9417
        0.1406    0.8828
        0.1555    0.8335
        0.1705    0.7837
        0.1855    0.7474
        0.2004    0.7100
        0.2154    0.6797
        0.2304    0.6491
        0.2453    0.6243
        0.2603    0.5960
        0.2753    0.5782
        0.2902    0.5583
        0.3052    0.5291
        0.3202    0.5186
        0.3351    0.5012
        0.3501    0.4834
        0.3651    0.4608
        0.3800    0.4553
        0.3950    0.4370
        0.4100    0.4258
        0.4249    0.4107
        0.4399    0.3897
        0.4549    0.3948
        0.4698    0.3682
        0.4848    0.3720
        0.4998    0.3369
        0.5147    0.3507
        0.5297    0.3314
        0.5447    0.3241
        0.5596    0.2991
        0.5746    0.3133
        0.5896    0.2886
        0.6045    0.2837
        0.6195    0.2680
        0.6345    0.2696
        0.6494    0.2539
        0.6644    0.2571
        0.6794    0.2364
        0.6943    0.2316
        0.7093    0.2253
        0.7243    0.2095
        0.7392    0.2062
        0.7542    0.2025
        0.7692    0.1915
        0.7841    0.1812
        0.7991    0.1669
        0.8141    0.1687
        0.8290    0.1573
        0.8440    0.1450
        0.8590    0.1440
        0.8739    0.1390
        0.8889    0.1194
        0.9039    0.1072
        0.9188    0.1015
        0.9338    0.0930
        0.9488    0.0794
        0.9637    0.0665
        0.9787    0.0439
        0.9931    0.0432
        1.0000   -0.0000];

    xfoil2cp=[         0    0.6060  %NACA 0010 @ 5 deg, inviscous
        0.0004    1.7615
        0.0012    2.6581
        0.0023    3.1957
        0.0039    3.4250
        0.0059    3.4460
        0.0083    3.3428
        0.0113    3.1727
        0.0150    2.9674
        0.0194    2.7467
        0.0250    2.5199
        0.0318    2.2953
        0.0404    2.0767
        0.0508    1.8728
        0.0631    1.6893
        0.0769    1.5302
        0.0917    1.3948
        0.1072    1.2804
        0.1232    1.1830
        0.1395    1.0990
        0.1561    1.0257
        0.1729    0.9618
        0.1898    0.9043
        0.2068    0.8531
        0.2239    0.8065
        0.2411    0.7645
        0.2584    0.7257
        0.2758    0.6901
        0.2931    0.6570
        0.3106    0.6263
        0.3281    0.5976
        0.3456    0.5710
        0.3631    0.5452
        0.3807    0.5221
        0.3983    0.4995
        0.4159    0.4781
        0.4336    0.4580
        0.4512    0.4387
        0.4689    0.4205
        0.4866    0.4028
        0.5044    0.3862
        0.5221    0.3698
        0.5398    0.3544
        0.5576    0.3395
        0.5753    0.3250
        0.5931    0.3108
        0.6109    0.2977
        0.6287    0.2839
        0.6464    0.2720
        0.6642    0.2586
        0.6820    0.2468
        0.6998    0.2349
        0.7176    0.2227
        0.7354    0.2112
        0.7532    0.2000
        0.7710    0.1885
        0.7888    0.1771
        0.8066    0.1660
        0.8244    0.1547
        0.8421    0.1435
        0.8599    0.1315
        0.8777    0.1204
        0.8954    0.1079
        0.9131    0.0960
        0.9308    0.0825
        0.9482    0.0691
        0.9650    0.0543
        0.9803    0.0386
        0.9931    0.0226
        1.0000   -0.0000];

    xfoil3cp=[    0.0000   -0.1550   %NACA 0020 @ 5 deg, inviscous
        0.0002   -0.4690
        0.0007   -0.7795
        0.0013   -1.0774
        0.0022   -1.3533
        0.0034   -1.5987
        0.0048   -1.8079
        0.0065   -1.9795
        0.0084   -2.1135
        0.0107   -2.2118
        0.0131   -2.2777
        0.0159   -2.3169
        0.0189   -2.3311
        0.0222   -2.3273
        0.0257   -2.3081
        0.0296   -2.2756
        0.0339   -2.2325
        0.0384   -2.1836
        0.0434   -2.1276
        0.0487   -2.0670
        0.0545   -2.0036
        0.0607   -1.9362
        0.0675   -1.8685
        0.0749   -1.7983
        0.0828   -1.7273
        0.0915   -1.6553
        0.1010   -1.5838
        0.1112   -1.5111
        0.1224   -1.4395
        0.1344   -1.3679
        0.1475   -1.2974
        0.1616   -1.2279
        0.1768   -1.1599
        0.1930   -1.0938
        0.2101   -1.0300
        0.2283   -0.9684
        0.2472   -0.9097
        0.2670   -0.8539
        0.2875   -0.8005
        0.3087   -0.7508
        0.3304   -0.7033
        0.3526   -0.6588
        0.3753   -0.6168
        0.3984   -0.5776
        0.4218   -0.5402
        0.4456   -0.5053
        0.4696   -0.4725
        0.4939   -0.4415
        0.5185   -0.4122
        0.5432   -0.3845
        0.5681   -0.3582
        0.5932   -0.3333
        0.6184   -0.3097
        0.6437   -0.2871
        0.6690   -0.2654
        0.6945   -0.2445
        0.7199   -0.2246
        0.7453   -0.2051
        0.7707   -0.1865
        0.7960   -0.1681
        0.8210   -0.1504
        0.8457   -0.1330
        0.8699   -0.1159
        0.8934   -0.0992
        0.9159   -0.0828
        0.9371   -0.0668
        0.9566   -0.0513
        0.9744   -0.0354
        0.9904   -0.0201
        1.0000    0.0000];

    xfoil4cp=[         0   -0.0850  %NACA 0030 @ 5 deg, inviscous
        0.0002   -0.2558 
        0.0006   -0.4273
        0.0012   -0.5984
        0.0020   -0.7666
        0.0030   -0.9300
        0.0043   -1.0864
        0.0058   -1.2344
        0.0075   -1.3712
        0.0095   -1.4968
        0.0117   -1.6101
        0.0141   -1.7094
        0.0169   -1.7958
        0.0198   -1.8672
        0.0231   -1.9271
        0.0266   -1.9737
        0.0304   -2.0081
        0.0345   -2.0317
        0.0389   -2.0446
        0.0436   -2.0482
        0.0487   -2.0433
        0.0541   -2.0304
        0.0598   -2.0098
        0.0659   -1.9844
        0.0725   -1.9517
        0.0794   -1.9151
        0.0868   -1.8734
        0.0947   -1.8277
        0.1031   -1.7791
        0.1121   -1.7269
        0.1216   -1.6713
        0.1318   -1.6148
        0.1426   -1.5548
        0.1540   -1.4945
        0.1663   -1.4320
        0.1792   -1.3690
        0.1930   -1.3053
        0.2076   -1.2410
        0.2230   -1.1772
        0.2394   -1.1133
        0.2566   -1.0506
        0.2747   -0.9884
        0.2938   -0.9276
        0.3139   -0.8683
        0.3348   -0.8110
        0.3568   -0.7551
        0.3796   -0.7016
        0.4033   -0.6503
        0.4280   -0.6013
        0.4535   -0.5546
        0.4798   -0.5102
        0.5069   -0.4682
        0.5347   -0.4284
        0.5632   -0.3907
        0.5923   -0.3553
        0.6219   -0.3219
        0.6520   -0.2902
        0.6824   -0.2602
        0.7131   -0.2321
        0.7439   -0.2051
        0.7747   -0.1797
        0.8053   -0.1553
        0.8355   -0.1322
        0.8651   -0.1101
        0.8936   -0.0891
        0.9206   -0.0692
        0.9456   -0.0507
        0.9682   -0.0329
        0.9881   -0.0169
        1.0000         0];

    xfoil5cp=[    0.0000   -0.0659   %NACA 0040 @ 5 deg, inviscous
        0.0003   -0.1981
        0.0007   -0.3299
        0.0014   -0.4613
        0.0024   -0.5912
        0.0036   -0.7193
        0.0050   -0.8442
        0.0067   -0.9655
        0.0086   -1.0823
        0.0108   -1.1939
        0.0132   -1.2994
        0.0159   -1.3988
        0.0188   -1.4905
        0.0220   -1.5754
        0.0254   -1.6524
        0.0291   -1.7214
        0.0331   -1.7825
        0.0373   -1.8359
        0.0418   -1.8808
        0.0466   -1.9180
        0.0517   -1.9476
        0.0571   -1.9695
        0.0628   -1.9840
        0.0687   -1.9915
        0.0750   -1.9923
        0.0816   -1.9868
        0.0886   -1.9746
        0.0959   -1.9569
        0.1036   -1.9333
        0.1116   -1.9052
        0.1201   -1.8712
        0.1289   -1.8339
        0.1382   -1.7916
        0.1480   -1.7452
        0.1582   -1.6961
        0.1689   -1.6433
        0.1802   -1.5875
        0.1920   -1.5298
        0.2044   -1.4696
        0.2175   -1.4076
        0.2312   -1.3443
        0.2457   -1.2797
        0.2609   -1.2145
        0.2769   -1.1487
        0.2938   -1.0828
        0.3116   -1.0171
        0.3304   -0.9520
        0.3502   -0.8876
        0.3712   -0.8243
        0.3933   -0.7623
        0.4166   -0.7021
        0.4412   -0.6435
        0.4672   -0.5872
        0.4945   -0.5331
        0.5231   -0.4815
        0.5530   -0.4322
        0.5843   -0.3858
        0.6167   -0.3417
        0.6502   -0.3006
        0.6846   -0.2619
        0.7197   -0.2258
        0.7552   -0.1920
        0.7908   -0.1605
        0.8263   -0.1312
        0.8612   -0.1039
        0.8950   -0.0786
        0.9272   -0.0554
        0.9570   -0.0341
        0.9839   -0.0157
        1.0000         0];

    xfoilvisccp=[    0.0008   -0.9823  %NACA 0001 @ 5 deg, Re =10^4
        0.0033   -3.3427
        0.0089   -2.4158
        0.0210   -1.9206
        0.0358   -1.5890
        0.0508   -1.3899
        0.0657   -1.2479
        0.0807   -1.1388
        0.0957   -1.0512
        0.1106   -0.9784
        0.1256   -0.9163
        0.1406   -0.8624
        0.1555   -0.8150
        0.1705   -0.7727
        0.1855   -0.7346
        0.2004   -0.7000
        0.2154   -0.6684
        0.2304   -0.6392
        0.2453   -0.6122
        0.2603   -0.5871
        0.2753   -0.5635
        0.2902   -0.5415
        0.3052   -0.5206
        0.3202   -0.5010
        0.3351   -0.4824
        0.3501   -0.4648
        0.3651   -0.4480
        0.3800   -0.4319
        0.3950   -0.4166
        0.4100   -0.4019
        0.4249   -0.3876
        0.4399   -0.3741
        0.4549   -0.3610
        0.4698   -0.3482
        0.4848   -0.3361
        0.4998   -0.3241
        0.5147   -0.3126
        0.5297   -0.3013
        0.5447   -0.2905
        0.5596   -0.2796
        0.5746   -0.2693
        0.5896   -0.2591
        0.6045   -0.2491
        0.6195   -0.2394
        0.6345   -0.2297
        0.6494   -0.2202
        0.6644   -0.2110
        0.6794   -0.2019
        0.6943   -0.1929
        0.7093   -0.1839
        0.7243   -0.1751
        0.7392   -0.1664
        0.7542   -0.1575
        0.7692   -0.1488
        0.7841   -0.1400
        0.7991   -0.1313
        0.8141   -0.1227
        0.8290   -0.1139
        0.8440   -0.1050
        0.8590   -0.0959
        0.8739   -0.0872
        0.8889   -0.0777
        0.9039   -0.0685
        0.9188   -0.0590
        0.9338   -0.0494
        0.9488   -0.0394
        0.9637   -0.0293
        0.9787   -0.0177
        0.9931   -0.0056
        1.0000   -0.0000];

    xfoilvisc2=[    0.0000   -0.5949  %NACA 0010 @ 5 deg, Re =10^6
        0.0004   -1.7301
        0.0012   -2.6180
        0.0023   -3.1496
        0.0039   -3.3816
        0.0059   -3.4075
        0.0083   -3.3108
        0.0113   -3.1481
        0.0150   -2.9506
        0.0194   -2.7377
        0.0250   -2.5217
        0.0318   -2.3086
        0.0404   -2.1067
        0.0508   -1.9204
        0.0631   -1.7536
        0.0769   -1.5050
        0.0917   -1.3608
        0.1072   -1.2557
        0.1232   -1.1673
        0.1395   -1.0883
        0.1561   -1.0187
        0.1729   -0.9564
        0.1898   -0.9006
        0.2068   -0.8504
        0.2239   -0.8044
        0.2411   -0.7630
        0.2584   -0.7248
        0.2758   -0.6895
        0.2931   -0.6570
        0.3106   -0.6266
        0.3281   -0.5983
        0.3456   -0.5718
        0.3631   -0.5467
        0.3807   -0.5235
        0.3983   -0.5014
        0.4159   -0.4803
        0.4336   -0.4605
        0.4512   -0.4414
        0.4689   -0.4234
        0.4866   -0.4062
        0.5044   -0.3898
        0.5221   -0.3738
        0.5398   -0.3586
        0.5576   -0.3440
        0.5753   -0.3300
        0.5931   -0.3162
        0.6109   -0.3032
        0.6287   -0.2902
        0.6464   -0.2782
        0.6642   -0.2659
        0.6820   -0.2544
        0.6998   -0.2430
        0.7176   -0.2318
        0.7354   -0.2211
        0.7532   -0.2107
        0.7710   -0.2005
        0.7888   -0.1905
        0.8066   -0.1810
        0.8244   -0.1717
        0.8421   -0.1627
        0.8599   -0.1534
        0.8777   -0.1438
        0.8954   -0.1324
        0.9131   -0.1180
        0.9308   -0.1006
        0.9482   -0.0802
        0.9650   -0.0564
        0.9803   -0.0310
        0.9931   -0.0062
        1.0000         0];

    state.alpha=(5*pi/180);
    geo.nx=30;
    geo.meshtype=1;

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
       cd(settings.hdir)

        figure(17)
        h=plot(lattice.VORTEX(:,4,1),-results.cp);
        hold on
        h2=plot(xfoilcp5deg(:,1),xfoilcp5deg(:,2),'r-.');
        h3=plot(xfoil2cp(:,1),xfoil2cp(:,2),'-ro');
        h4=plot(xfoil3cp(:,1),-xfoil3cp(:,2),'-rs');
        h5=plot(xfoil4cp(:,1),-xfoil4cp(:,2),'-rd');
        h6=plot(xfoil5cp(:,1),-xfoil5cp(:,2),'-r^');

        set(h,'Linewidth',2)
        set(h2,'Linewidth',2)
        set(h3,'Linewidth',2)
        set(h4,'Linewidth',2)
        set(h5,'Linewidth',2)
        set(h6,'Linewidth',2)

        title('Pressure difference distribution')
        xlabel('Chordwise position, x/c, [.]')
        ylabel('Difference pressure coefficient, -  \DeltaCp, [-]')
    legend('Tornado','XFOIL NACA0001','XFOIL NACA0010','XFOIL NACA0020','XFOIL NACA0030','XFOIL NACA0040')
        grid

        xfoilcl=[0.5575 0.5940 0.6411 0.6891 0.7377];
        xfoilcm=[0.009 -0.0055 -0.014 -0.0255 -0.0398];

        clerr=(results.CL-xfoilcl)/results.CL

        figure(24)
        subplot(2,1,1)
        h=bar([clerr],0.75,'grouped');
        h2=gca;
        set(h2,'XTick',1:1:5);
        set(h2,'XTickLabel',{'Naca 0001','Naca 0010','Naca 0020','Naca 0030','Naca 0040'});
        ylabel('Relative Tornado Lift coefficient error, (L_T-L_X)/L_T ,[-]')
        title('Relative error between Xfoil vs Tornado @ \alpha=5 deg.')

        subplot(2,1,2)
        h=bar([xfoilcm],0.75,'grouped');
        h2=gca;
        set(h2,'XTick',1:1:5);
        set(h2,'XTickLabel',{'Naca 0001','Naca 0010','Naca 0020','Naca 0030','Naca 0040'});

        ylabel('Xfoil Cm,[-], Tornado = 0.0')

        %break
        %new case
        geo.foil(:,:,1)={'N64210.DAT'};
        geo.foil(:,:,2)={'N64210.DAT'};

        quest=1;                  
        results=[];                 
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        xfoilcp5deg=[         0    0.5239
        0.0001    1.6220
        0.0006    2.5830
        0.0012    3.2936
        0.0021    3.7885
        0.0032    4.1105
        0.0047    4.0847
        0.0066    3.7635
        0.0088    3.4630
        0.0116    3.1611
        0.0152    2.8670
        0.0199    2.5458
        0.0261    2.3189
        0.0339    2.1359
        0.0433    1.9722
        0.0533    1.8267
        0.0636    1.6945
        0.0742    1.5897
        0.0852    1.5126
        0.0964    1.4472
        0.1077    1.3849
        0.1191    1.3257
        0.1305    1.2711
        0.1419    1.2222
        0.1533    1.1826
        0.1647    1.1509
        0.1762    1.1232
        0.1877    1.0972
        0.1993    1.0714
        0.2109    1.0429
        0.2225    1.0138
        0.2341    0.9867
        0.2457    0.9620
        0.2572    0.9428
        0.2688    0.9285
        0.2803    0.9138
        0.2919    0.9002
        0.3034    0.8837
        0.3150    0.8647
        0.3266    0.8452
        0.3383    0.8267
        0.3499    0.8100
        0.3615    0.7988
        0.3730    0.7863
        0.3845    0.7765
        0.3959    0.7648
        0.4073    0.7494
        0.4187    0.7343
        0.4302    0.7166
        0.4417    0.7013
        0.4532    0.6854
        0.4648    0.6726
        0.4764    0.6582
        0.4880    0.6462
        0.4996    0.6322
        0.5112    0.6176
        0.5229    0.6017
        0.5345    0.5878
        0.5461    0.5728
        0.5578    0.5608
        0.5694    0.5482
        0.5811    0.5398
        0.5928    0.5273
        0.6044    0.5155
        0.6161    0.5028
        0.6278    0.4872
        0.6394    0.4750
        0.6511    0.4623
        0.6628    0.4516
        0.6745    0.4431
        0.6862    0.4344
        0.6979    0.4266
        0.7097    0.4173
        0.7214    0.4078
        0.7331    0.3982
        0.7449    0.3887
        0.7566    0.3768
        0.7683    0.3668
        0.7801    0.3548
        0.7918    0.3439
        0.8035    0.3342
        0.8152    0.3258
        0.8268    0.3159
        0.8384    0.3088
        0.8500    0.2985
        0.8615    0.2884
        0.8730    0.2798
        0.8845    0.2688
        0.8960    0.2575
        0.9075    0.2519
        0.9191    0.2422
        0.9307    0.2325
        0.9421    0.2218
        0.9530    0.2054
        0.9631    0.1857
        0.9724    0.1637
        0.9809    0.1366
        0.9886    0.1079
        0.9956    0.0685
        1.0000         0];






        figure(18)
        h=plot(lattice.VORTEX(:,4,1),-results.cp);
        hold on
        hold on
        h2=plot(xfoilcp5deg(:,1),xfoilcp5deg(:,2),'r-.');


        set(h,'Linewidth',2)
        set(h2,'Linewidth',2)

        title('Pressure difference distribution NACA24210, \alpha = 5 deg.')
        xlabel('Chordwise position, x/c, [.]')
        ylabel('Difference pressure coefficient, -  \DeltaCp, [-]')
        legend('Tornado','XFOIL')
        grid


        %newcase
        xfoil0=[         0   -0.2041
        0.0001   -0.5684
        0.0006   -0.8425
        0.0012   -1.0251
        0.0021   -1.1300
        0.0032   -1.1742
        0.0047   -1.2002
        0.0066   -1.1900
        0.0088   -1.0576
        0.0116   -0.9486
        0.0152   -0.8395
        0.0199   -0.7330
        0.0261   -0.5903
        0.0339   -0.4893
        0.0433   -0.4147
        0.0533   -0.3591
        0.0636   -0.3234
        0.0742   -0.2883
        0.0852   -0.2489
        0.0964   -0.2122
        0.1077   -0.1864
        0.1191   -0.1685
        0.1305   -0.1541
        0.1419   -0.1411
        0.1533   -0.1259
        0.1647   -0.1075
        0.1762   -0.0899
        0.1877   -0.0732
        0.1993   -0.0594
        0.2109   -0.0502
        0.2225   -0.0443
        0.2341   -0.0385
        0.2457   -0.0328
        0.2572   -0.0243
        0.2688   -0.0134
        0.2803   -0.0037
        0.2919    0.0064
        0.3034    0.0135
        0.3150    0.0180
        0.3266    0.0221
        0.3383    0.0253
        0.3499    0.0293
        0.3615    0.0356
        0.3730    0.0394
        0.3845    0.0461
        0.3959    0.0506
        0.4073    0.0550
        0.4187    0.0591
        0.4302    0.0629
        0.4417    0.0675
        0.4532    0.0716
        0.4648    0.0766
        0.4764    0.0809
        0.4880    0.0853
        0.4996    0.0890
        0.5112    0.0915
        0.5229    0.0921
        0.5345    0.0945
        0.5461    0.0948
        0.5578    0.0981
        0.5694    0.1006
        0.5811    0.1048
        0.5928    0.1068
        0.6044    0.1090
        0.6161    0.1091
        0.6278    0.1081
        0.6394    0.1076
        0.6511    0.1082
        0.6628    0.1098
        0.6745    0.1134
        0.6862    0.1170
        0.6979    0.1199
        0.7097    0.1232
        0.7214    0.1246
        0.7331    0.1260
        0.7449    0.1270
        0.7566    0.1266
        0.7683    0.1267
        0.7801    0.1261
        0.7918    0.1251
        0.8035    0.1262
        0.8152    0.1274
        0.8268    0.1288
        0.8384    0.1306
        0.8500    0.1311
        0.8615    0.1309
        0.8730    0.1302
        0.8845    0.1298
        0.8960    0.1287
        0.9075    0.1313
        0.9191    0.1335
        0.9307    0.1336
        0.9421    0.1334
        0.9530    0.1270
        0.9631    0.1178
        0.9724    0.1052
        0.9809    0.0897
        0.9886    0.0708
        0.9956    0.0461
        1.0000         0];

        state.alpha=-1.63*pi/180;
        quest=1;                  
        results=[];                 
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        figure(19)
        h=plot(lattice.VORTEX(:,4,1),-results.cp);
        hold on
        hold on
        h2=plot(xfoil0(:,1),xfoil0(:,2),'r-.');


        set(h,'Linewidth',2)
        set(h2,'Linewidth',2)

        title('Pressure difference distribution, NACA24210 C_L = 0')
        xlabel('Chordwise position, x/c, [.]')
        ylabel('Difference pressure coefficient,  -  \DeltaCp, [-]')
        legend('Tornado','XFOIL ')
        grid on



        %newcase
        naca0001_5_i=[    0.0008  -27.3608
        0.0033   -4.2785
        0.0089   -3.9581
        0.0210   -2.3463
        0.0358   -1.8600
        0.0508   -1.5428
        0.0657   -1.3479
        0.0807   -1.2068
        0.0957   -1.0991
        0.1106   -1.0126
        0.1256   -0.9417
        0.1406   -0.8829
        0.1555   -0.8335
        0.1705   -0.7837
        0.1855   -0.7474
        0.2004   -0.7100
        0.2154   -0.6798
        0.2304   -0.6491
        0.2453   -0.6243
        0.2603   -0.5960
        0.2753   -0.5782
        0.2902   -0.5583
        0.3052   -0.5291
        0.3202   -0.5186
        0.3351   -0.5012
        0.3501   -0.4834
        0.3651   -0.4608
        0.3800   -0.4553
        0.3950   -0.4370
        0.4100   -0.4258
        0.4249   -0.4107
        0.4399   -0.3897
        0.4549   -0.3948
        0.4698   -0.3681
        0.4848   -0.3720
        0.4998   -0.3369
        0.5147   -0.3507
        0.5297   -0.3314
        0.5447   -0.3241
        0.5596   -0.2992
        0.5746   -0.3133
        0.5896   -0.2886
        0.6045   -0.2837
        0.6195   -0.2680
        0.6345   -0.2697
        0.6494   -0.2540
        0.6644   -0.2572
        0.6794   -0.2364
        0.6943   -0.2316
        0.7093   -0.2253
        0.7243   -0.2095
        0.7392   -0.2063
        0.7542   -0.2025
        0.7692   -0.1916
        0.7841   -0.1811
        0.7991   -0.1669
        0.8141   -0.1688
        0.8290   -0.1573
        0.8440   -0.1449
        0.8590   -0.1440
        0.8739   -0.1390
        0.8889   -0.1194
        0.9039   -0.1072
        0.9188   -0.1015
        0.9338   -0.0929
        0.9488   -0.0794
        0.9637   -0.0664
        0.9787   -0.0440
        0.9931   -0.0432
        1.0000         0];

    naca1401_5_i=[    0.0007  -17.8528
        0.0033   -4.4396
        0.0087   -3.8292
        0.0207   -2.3584
        0.0355   -1.8970
        0.0505   -1.6037
        0.0655   -1.4260
        0.0804   -1.2967
        0.0954   -1.2014
        0.1104   -1.1250
        0.1254   -1.0627
        0.1403   -1.0115
        0.1553   -0.9650
        0.1703   -0.9284
        0.1852   -0.8908
        0.2002   -0.8622
        0.2152   -0.8334
        0.2301   -0.8074
        0.2451   -0.7853
        0.2601   -0.7615
        0.2751   -0.7411
        0.2900   -0.7249
        0.3050   -0.6999
        0.3200   -0.6867
        0.3349   -0.6641
        0.3499   -0.6540
        0.3649   -0.6323
        0.3799   -0.6145
        0.3948   -0.6030
        0.4098   -0.5772
        0.4248   -0.5607
        0.4397   -0.5559
        0.4547   -0.5303
        0.4697   -0.5190
        0.4847   -0.5126
        0.4996   -0.4985
        0.5146   -0.4727
        0.5296   -0.4746
        0.5445   -0.4617
        0.5595   -0.4496
        0.5745   -0.4323
        0.5895   -0.4270
        0.6044   -0.4103
        0.6194   -0.4104
        0.6344   -0.3964
        0.6494   -0.3844
        0.6643   -0.3660
        0.6793   -0.3615
        0.6943   -0.3594
        0.7093   -0.3330
        0.7242   -0.3388
        0.7392   -0.3171
        0.7542   -0.2996
        0.7691   -0.3087
        0.7841   -0.2778
        0.7991   -0.2782
        0.8141   -0.2643
        0.8290   -0.2474
        0.8440   -0.2414
        0.8590   -0.2290
        0.8739   -0.2082
        0.8889   -0.2027
        0.9039   -0.1848
        0.9188   -0.1663
        0.9338   -0.1553
        0.9488   -0.1276
        0.9638   -0.1144
        0.9787   -0.0781
        0.9931   -0.0554
        1.0000         0];

    naca2401_5_i=[    0.0007   -9.6360
        0.0032   -4.5701
        0.0086   -3.7018
        0.0204   -2.3686
        0.0352   -1.9311
        0.0502   -1.6629
        0.0652   -1.5016
        0.0801   -1.3880
        0.0951   -1.3029
        0.1100   -1.2376
        0.1250   -1.1832
        0.1399   -1.1406
        0.1549   -1.1002
        0.1699   -1.0683
        0.1848   -1.0404
        0.1998   -1.0133
        0.2148   -0.9890
        0.2298   -0.9670
        0.2447   -0.9486
        0.2597   -0.9253
        0.2747   -0.9091
        0.2897   -0.8890
        0.3046   -0.8752
        0.3196   -0.8524
        0.3346   -0.8418
        0.3496   -0.8163
        0.3646   -0.8048
        0.3796   -0.7865
        0.3945   -0.7580
        0.4095   -0.7393
        0.4245   -0.7197
        0.4395   -0.6993
        0.4545   -0.6794
        0.4695   -0.6729
        0.4845   -0.6538
        0.4995   -0.6405
        0.5144   -0.6224
        0.5294   -0.6161
        0.5444   -0.5953
        0.5594   -0.5863
        0.5744   -0.5709
        0.5894   -0.5657
        0.6043   -0.5393
        0.6193   -0.5430
        0.6343   -0.5164
        0.6493   -0.5130
        0.6643   -0.4923
        0.6793   -0.4921
        0.6942   -0.4655
        0.7092   -0.4562
        0.7242   -0.4414
        0.7392   -0.4352
        0.7542   -0.4213
        0.7691   -0.3988
        0.7841   -0.3922
        0.7991   -0.3741
        0.8141   -0.3588
        0.8290   -0.3413
        0.8440   -0.3334
        0.8590   -0.3073
        0.8740   -0.2963
        0.8890   -0.2760
        0.9039   -0.2499
        0.9189   -0.2397
        0.9339   -0.2074
        0.9488   -0.1838
        0.9638   -0.1570
        0.9787   -0.1130
        0.9931   -0.0699
        1.0000         0];


    %airfoil coords
    coords=[    1.0000    0.0001    0.0001    0.0001
        0.9931    0.0002    0.0004    0.0006
        0.9787    0.0004    0.0010    0.0017
        0.9637    0.0005    0.0017    0.0029
        0.9488    0.0007    0.0023    0.0039
        0.9338    0.0008    0.0029    0.0050
        0.9188    0.0010    0.0035    0.0060
        0.9039    0.0012    0.0041    0.0070
        0.8889    0.0013    0.0047    0.0080
        0.8739    0.0015    0.0052    0.0090
        0.8590    0.0016    0.0058    0.0099
        0.8440    0.0018    0.0063    0.0108
        0.8290    0.0019    0.0068    0.0117
        0.8141    0.0021    0.0073    0.0125
        0.7991    0.0022    0.0078    0.0133
        0.7841    0.0023    0.0082    0.0141
        0.7692    0.0025    0.0087    0.0149
        0.7542    0.0026    0.0091    0.0156
        0.7392    0.0027    0.0095    0.0163
        0.7243    0.0029    0.0099    0.0170
        0.7093    0.0030    0.0103    0.0177
        0.6943    0.0031    0.0107    0.0183
        0.6794    0.0032    0.0110    0.0189
        0.6644    0.0033    0.0114    0.0194
        0.6494    0.0034    0.0117    0.0200
        0.6345    0.0036    0.0120    0.0205
        0.6195    0.0037    0.0123    0.0210
        0.6045    0.0038    0.0126    0.0214
        0.5896    0.0039    0.0129    0.0219
        0.5746    0.0040    0.0131    0.0223
        0.5596    0.0041    0.0134    0.0226
        0.5447    0.0042    0.0136    0.0230
        0.5297    0.0042    0.0138    0.0233
        0.5147    0.0043    0.0140    0.0236
        0.4998    0.0044    0.0141    0.0239
        0.4848    0.0045    0.0143    0.0241
        0.4698    0.0046    0.0144    0.0243
        0.4549    0.0046    0.0145    0.0245
        0.4399    0.0047    0.0146    0.0246
        0.4249    0.0048    0.0147    0.0247
        0.4100    0.0048    0.0148    0.0248
        0.3950    0.0049    0.0148    0.0248
        0.3800    0.0049    0.0149    0.0248
        0.3651    0.0049    0.0149    0.0248
        0.3501    0.0050    0.0148    0.0246
        0.3351    0.0050    0.0147    0.0245
        0.3202    0.0050    0.0146    0.0242
        0.3052    0.0050    0.0144    0.0239
        0.2902    0.0050    0.0142    0.0235
        0.2753    0.0050    0.0140    0.0230
        0.2603    0.0050    0.0138    0.0225
        0.2453    0.0049    0.0134    0.0219
        0.2304    0.0049    0.0131    0.0213
        0.2154    0.0048    0.0127    0.0206
        0.2004    0.0048    0.0123    0.0198
        0.1855    0.0047    0.0118    0.0189
        0.1705    0.0046    0.0113    0.0180
        0.1555    0.0045    0.0108    0.0170
        0.1406    0.0044    0.0102    0.0159
        0.1256    0.0042    0.0095    0.0148
        0.1106    0.0040    0.0088    0.0136
        0.0957    0.0038    0.0081    0.0123
        0.0807    0.0036    0.0072    0.0109
        0.0657    0.0033    0.0063    0.0094
        0.0508    0.0030    0.0054    0.0077
        0.0358    0.0026    0.0043    0.0060
        0.0210    0.0020    0.0030    0.0041
        0.0089    0.0013    0.0018    0.0022
        0.0033    0.0008    0.0010    0.0012
        0.0008    0.0004    0.0005    0.0005
        0.0008   -0.0004   -0.0004   -0.0003
        0.0033   -0.0008   -0.0007   -0.0005
        0.0089   -0.0013   -0.0009   -0.0005
        0.0210   -0.0020   -0.0010    0.0000
        0.0358   -0.0026   -0.0009    0.0008
        0.0508   -0.0030   -0.0006    0.0017
        0.0657   -0.0033   -0.0003    0.0027
        0.0807   -0.0036    0.0000    0.0036
        0.0957   -0.0038    0.0004    0.0045
        0.1106   -0.0040    0.0007    0.0055
        0.1256   -0.0042    0.0011    0.0063
        0.1406   -0.0044    0.0014    0.0072
        0.1555   -0.0045    0.0018    0.0080
        0.1705   -0.0046    0.0021    0.0088
        0.1855   -0.0047    0.0024    0.0095
        0.2004   -0.0048    0.0027    0.0102
        0.2154   -0.0048    0.0030    0.0109
        0.2304   -0.0049    0.0033    0.0115
        0.2453   -0.0049    0.0036    0.0120
        0.2603   -0.0050    0.0038    0.0126
        0.2753   -0.0050    0.0040    0.0130
        0.2902   -0.0050    0.0042    0.0135
        0.3052   -0.0050    0.0044    0.0139
        0.3202   -0.0050    0.0046    0.0142
        0.3351   -0.0050    0.0048    0.0145
        0.3501   -0.0050    0.0049    0.0147
        0.3651   -0.0049    0.0050    0.0149
        0.3800   -0.0049    0.0051    0.0151
        0.3950   -0.0049    0.0051    0.0151
        0.4100   -0.0048    0.0052    0.0152
        0.4249   -0.0048    0.0052    0.0152
        0.4399   -0.0047    0.0053    0.0152
        0.4549   -0.0046    0.0053    0.0152
        0.4698   -0.0046    0.0053    0.0152
        0.4848   -0.0045    0.0053    0.0151
        0.4998   -0.0044    0.0053    0.0150
        0.5147   -0.0043    0.0053    0.0149
        0.5297   -0.0042    0.0053    0.0148
        0.5447   -0.0042    0.0053    0.0147
        0.5596   -0.0041    0.0052    0.0145
        0.5746   -0.0040    0.0052    0.0143
        0.5896   -0.0039    0.0051    0.0141
        0.6045   -0.0038    0.0051    0.0139
        0.6195   -0.0037    0.0050    0.0137
        0.6345   -0.0036    0.0049    0.0134
        0.6494   -0.0034    0.0048    0.0131
        0.6644   -0.0033    0.0047    0.0128
        0.6794   -0.0032    0.0046    0.0124
        0.6943   -0.0031    0.0045    0.0121
        0.7093   -0.0030    0.0044    0.0117
        0.7243   -0.0029    0.0042    0.0113
        0.7392   -0.0027    0.0041    0.0109
        0.7542   -0.0026    0.0039    0.0104
        0.7692   -0.0025    0.0037    0.0100
        0.7841   -0.0023    0.0036    0.0095
        0.7991   -0.0022    0.0034    0.0090
        0.8141   -0.0021    0.0032    0.0084
        0.8290   -0.0019    0.0030    0.0079
        0.8440   -0.0018    0.0028    0.0073
        0.8590   -0.0016    0.0025    0.0067
        0.8739   -0.0015    0.0023    0.0060
        0.8889   -0.0013    0.0020    0.0054
        0.9039   -0.0012    0.0018    0.0047
        0.9188   -0.0010    0.0015    0.0040
        0.9338   -0.0008    0.0012    0.0033
        0.9488   -0.0007    0.0009    0.0026
        0.9637   -0.0005    0.0007    0.0018
        0.9787   -0.0004    0.0003    0.0010
        0.9931   -0.0002    0.0000    0.0003
        1.0000   -0.0001   -0.0001   -0.0001];

        state.alpha=5*pi/180;

        geo.foil(:,:,1)={'0001'};
        geo.foil(:,:,2)={'0001'};
        geo.nx=50;
        quest=1;                  
        results=[];                 
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);
       cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
        R.alpha(1)=state.alpha;
        R.CL(1)=results.CL;
        R.CD(1)=results.CD;
        R.Cm(1)=results.Cm;
        R.cp(:,1)=results.cp;

        geo.foil(:,:,1)={'1401'};
        geo.foil(:,:,2)={'1401'};
        quest=1;                  
        results=[];                 
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);
       cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
        R.alpha(2)=state.alpha;
        R.CL(2)=results.CL;
        R.CD(2)=results.CD;
        R.Cm(2)=results.Cm;
        R.cp(:,2)=results.cp;

        geo.foil(:,:,1)={'2401'};
        geo.foil(:,:,2)={'2401'};
        quest=1;                  
        results=[];                 
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);
       cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
        R.alpha(3)=state.alpha;
        R.CL(3)=results.CL;
        R.CD(3)=results.CD;
        R.Cm(3)=results.Cm;
        R.cp(:,3)=results.cp;




        figure(22)
        h=plot(lattice.VORTEX(:,4,1),-R.cp(:,1),'b-');
        set(h,'Linewidth',2),hold on
        h=plot(lattice.VORTEX(:,4,1),-R.cp(:,2),'ob-');
        set(h,'Linewidth',2)
        h=plot(lattice.VORTEX(:,4,1),-R.cp(:,3),'sb-');
        set(h,'Linewidth',2)



        h2=plot(naca0001_5_i(:,1),-naca0001_5_i(:,2),'r-.');
            set(h2,'Linewidth',2)
        h2=plot(naca1401_5_i(:,1),-naca1401_5_i(:,2),'or-.');
            set(h2,'Linewidth',2)
        h2=plot(naca2401_5_i(:,1),-naca2401_5_i(:,2),'sr-.');
            set(h2,'Linewidth',2)



        axis([0 1 0 2])
        title('Pressure coefficient distribition, NACAx401 profile')
        xlabel('Chordwise position, x/c, [.]')
        ylabel('Difference pressure coefficient,  -  \DeltaCp, [-]')
        legend('Tornado NACA 0001','Tornado NACA 1401','Tornado NACA 2401','XFOIL NACA 0001 ','XFOIL NACA 1401' ,'XFOIL NACA 2401 ')
        grid on

        axes('position',[0.3 0.65 0.3 0.2])
        hold on
        h=plot(coords(:,1),coords(:,4),'k');
        set(h,'Linewidth',2)
        h=plot(coords(:,1),coords(:,3)+0.1,'k');
        set(h,'Linewidth',2)
        h=plot(coords(:,1),coords(:,2)+0.2,'k');
        set(h,'Linewidth',2)
        axis equal
        %axis off


        XfoilCL=[0.5575 0.6644 0.7724];
        XfoilCm=[0.009 -0.0275 -0.0556];

        %clerr=(R.CL-XfoilCL)./R.CL;
        %cmerr=(R.Cm-XfoilCm)./R.Cm;

        figure(23)
        subplot(2,1,1)
        h=bar([R.CL' XfoilCL'],0.75,'grouped');
        h2=gca;
        set(h2,'XTick',1:1:3);
        set(h2,'XTickLabel',{'Naca 0001','Naca 1401','Naca 2401'});
        legend('Tornado','XFOIL')
        ylabel('Lift coefficient, C_L, [-]')
        title('Different NACA profiles @ \alpha=5 deg.')

        subplot(2,1,2)
        h=bar([R.Cm' XfoilCm'],0.75,'grouped');
        h2=gca;
        set(h2,'XTick',1:1:3);
           set(h2,'XTickLabel',{'Naca 0001','Naca 1401','Naca 2401'});
        legend('Tornado','XFOIL')
        ylabel('Pitching moment coefficient, C_m, [-]')


        %break
        %newcase
        %new case
    B =[-3.0000   -0.1625    0.0052    0.0008   -0.0392
       -1.0000    0.0658    0.0045    0.0004   -0.0409
        1.0000    0.2891    0.0045    0.0005   -0.0424
        3.0000    0.5112    0.0058    0.0012   -0.0432
        4.0000    0.6234    0.0063    0.0016   -0.0436
        5.0000    0.7348    0.0068    0.0021   -0.0439
        6.0000    0.8447    0.0074    0.0029   -0.0440
        7.0000    0.9547    0.0079    0.0034   -0.0443
        8.0000    1.0635    0.0084    0.0039   -0.0444
        9.0000    1.1691    0.0092    0.0048   -0.0440
       10.0000    1.2721    0.0101    0.0058   -0.0432
       11.0000    1.3709    0.0109    0.0068   -0.0417
       12.0000    1.4684    0.0122    0.0081   -0.0403
       13.0000    1.5611    0.0137    0.0096   -0.0384
       14.0000    1.6453    0.0157    0.0116   -0.0353
       15.0000    1.7160    0.0181    0.0143   -0.0305
       16.0000    1.7598    0.0205    0.0167   -0.0213
       17.0000    1.7882    0.0240    0.0204   -0.0126
       18.0000    1.8113    0.0290    0.0256   -0.0065];

    A(:,1)=-4:1:15;
    A(:,2)=[-0.2790 -0.1620 -0.0444 0.0733 0.191 0.3086 0.4261 0.5434 0.6607 0.7777 .8944 1.0119 1.1271 1.243 1.3585 1.4735 1.5885 1.7023 1.8159 1.929]';
    A(:,3)=-0.001*[40:1.2:63];



       for i=1:20;   %Angle of attack
        alpha=(-4:1:16)*pi/(180);   
        state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)
        %results=trefftz5(results,state,geo,lattice,ref);

        R.alpha(i)=state.alpha;
        R.CL(i)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;
    %    R.TDC(i)=results.Trefftz_drag_Coeff;
       end

        figure(20)
        h2=plot(R.alpha*180/pi,R.CL);
        hold on
        h=plot(B(:,1),B(:,2),'r-.');
        set(h,'Linewidth',2)
        set(h2,'Linewidth',2)
        title('Liftcurve, NACA24210 profile')
        xlabel('Angle of Attack, \alpha, [deg]')
        ylabel('Lift coefficient, C_L, [-]')
        legend('Tornado','XFOIL ')
        grid on


        figure(21)
        h=plot(R.Cm,R.CL);
        hold on
        hold on
        h2=plot(B(:,5),B(:,2),'r:');
        h3=plot(A(:,3),A(:,2),'G-.');


        set(h,'Linewidth',2)
        set(h2,'Linewidth',2)
        set(h3,'Linewidth',2)

        title('Pitch moment for NACA24210 profile. Ref @ c/4')
        xlabel('Pitch moment coefficient, C_m, [-]')
        ylabel('Lift coefficient, C_L, [-]')
        legend('Tornado','XFOIL viscous', 'XFOIL inviscous')
        grid on




case 9
    %another testcase
    disp('Dihedral Validation')

    cd(settings.acdir)
        load('dihedral');
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    geo.nx=5;
    geo.ny=5;


    dihed=-0.8:0.1:0.8

    for j=1:17
    geo.dihed=dihed(j);

    alpha=[0 0.1];
    for i=1:2;    
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i)=state.alpha;
        R.CL(i)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;
    end

    CL_a(j)=diff(R.CL)/diff(R.alpha);

    end
    dihed2=[-45 -30 -15 0 15 30];       %G.H. Saunders, "Aerodynamic Characteristics of , june 65 185-192
    CLa2=[2 2.95 3.4 3.75 3.4 2.95];    %wings in ground proximity". Canadian aeronautics and space journal
                                        % Vol 11, pp 185-192, June 1965
    figure(25)
    h1=plot(dihed*180/pi,CL_a);
    hold on
    h2=plot(dihed2,CLa2,'o');
    xlabel('Dihedral')
    ylabel('Liftslope, CL_\alpha, [-]')

    set(h1,'Linewidth',2)
    set(h2,'Linewidth',2)    
    legend('Tornado','Reference')

    axis([-45 45 0 4])

    title('Effect of dihedral on liftslope for flat, unswept, rectangular AR=4 wing.')



    %% Dihedral Validation TN1732
case 10
    %another testcase
    disp('Dihedral Validation TN1732')

    cd(settings.acdir)
        load('NACATN1732');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;

    dihed=[-20 -10 0 10]*pi/180;
    state.P=0.01;
    for j=1:4
    geo.dihed=dihed(j);

    alpha=(-3:2:13)*pi/180;
    [kk void]=size(alpha');
    for i=1:kk;    
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i)=state.alpha;
        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end





    X.CY_P=[-0.0593 0.0000 0.0296 0.1037 0.1719 0.2074 0.2667 0.2311 0.1185];
    X.CL=  [-0.0691 0.0294 0.1176 0.2059 0.2971 0.3971 0.4853 0.5662 0.6765];
    X.Cn_P=[-0.0149 0.0000 0.0149 0.0328 0.0448 0.0522 0.0597 0.0448 -0.0299];
    X.Cl_P=-[0.2074 0.2074 0.2074 0.2074 0.2100 0.2148 0.2222 0.2444 0.3037];


    X.CY_P_dm10=[-5 -3 -1 0 1 2.8 5 4.2 3 0]/(27/0.8);
    X.CL_dm10=[-6.2 0 5 10.3 15.5 19 27.5 33.5 40 48]/68;

    X.CY_P_dp10=[0 3   6 7.2 8.5 12   13   13 11]/(27/0.8);
    X.CL_dp10= [-3 3.5 9 14  20  26.5 32.5 45 51.5]/68;


    R.CY_P=R.CY/(0.01*ref.b_ref/(2*state.AS));

    R.Cn_P=R.Cn/(0.01*ref.b_ref/(2*state.AS));

    R.Cl_P=R.Cl/(0.01*ref.b_ref/(2*state.AS));

    figure(26)
    h1=plot(R.CL,R.CY_P);
    set(h1,'Linewidth',2)
    hold on
    h2=plot(X.CL,-X.CY_P,'O');
    h3=plot(X.CL_dm10,-X.CY_P_dm10,'s');
    h4=plot(X.CL_dp10,-X.CY_P_dp10,'d');

    set(h2,'Linewidth',2)
    set(h3,'Linewidth',2)
    set(h4,'Linewidth',2)

    grid
    xlabel('Coefficient of Lift, C_L, [-]')
    ylabel('Sideforce coefficient roll derivative, C_{Y_p}, [-]')
    title('Effect of dihedral on sideforce coefficient roll derivative, AR=2.61 wing.')


    figure(27)
    h1=plot(R.CL,R.Cn_P);
    set(h1,'Linewidth',2)
    hold on
    h2=plot(X.CL,-X.Cn_P,'O');
    set(h2,'Linewidth',2)
    grid
    xlabel('Coefficient of Lift, C_L, [-]')
    ylabel('Yaw moment coefficient roll derivative, C_{n_p}, [-]')
    title('Effect of dihedral on Yaw moment coefficient roll derivative, AR=2.61 wing.')





    %% Dihedral Validation TN1668 #1
    case 11
    %another testcase

    disp('Dihedral Validation TN1668')

    cd(settings.acdir)
        load('NACATN1732');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;

    dihed=[10 0 -10 -20]*pi/180;
    for j=1:4
    geo.dihed=dihed(j);

    alpha=(-3:3:27)*pi/180;
    [kk void]=size(alpha');
    for i=1:kk;    
    state.alpha=alpha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end





    X.alpha=[   -0.6520   -0.3265         0    0.6531
        2.3905    2.7755    3.1565    3.6463
        6.5195    6.9660    7.1837    7.9456
       10.7572   11.1565   11.4286   12.1361
       14.9406   15.2925   15.6190   16.2721
       19.1239   19.5374   19.8095   20.4082
       23.3073   23.6190   23.8912   24.4354
       27.2733   27.5918   27.8639   28.3537
       31.1307   31.5102   31.8367   32.4354];


    X.CL=[   -0.0176   -0.0177    0.0044    0.0220
        0.0991    0.1106    0.1261    0.1410
        0.2819    0.3119    0.2987    0.3194
        0.4581    0.5044    0.4801    0.4802
        0.6564    0.7058    0.6836    0.6542
        0.8833    0.9469    0.9248    0.8612
        1.1145    1.0841    1.0133    0.9537
        1.1696    1.0774    1.0310    0.9383
        0.9978    0.9447    0.9336    0.8789];

    figure(32)
    %h2=plot(X.alpha,X.CL,'O');




    S1=['bo-';'rs-';'gd-';'k^-'];
    S2=['bo';'rs';'gd';'k^'];
    for j=1:4
        h1=plot(R.alpha(:,j)*180/pi,R.CL(:,j),S1(j,:));
        set(h1,'Linewidth',2)
        hold on
        h2=plot(X.alpha(:,j),X.CL(:,j),S2(j,:));
        set(h2,'Linewidth',2)
    end



    grid on
    ylabel('Lift coefficient, C_L, [-]')
    xlabel('Angle of attack, \alpha, [deg]')
    title('Effect of dihedral on Lift, AR=2.61 wing.')




    %% Dihedral Validation TN1668 #2
    case 12

    %another testcase
    disp('Dihedral Validation TN1668 #2 -Roll moment, dihedral =0')

    cd(settings.acdir)
        load('NACATN1732');
        
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;
    geo.dihed=0;


    alpha=[-0.4 2.8 15.2 23.6]*pi/180;
    for j=1:4

        state.alpha=alpha(j);

    betha=(-32:8:32)*pi/180;
    [kk void]=size(betha');
    for i=1:kk;    
    state.betha=betha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.betha(i,j)=state.betha;

        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end





    X.betha=[  -30.2656  -30.1838  -30.0973  -29.8495
      -25.1491  -25.0811  -25.0811  -24.7742
      -20.2927  -20.1514  -20.0649  -19.8710
      -15.0894  -15.0486  -15.0486  -14.7957
      -10.0596  -10.0324   -9.8595   -9.8925
       -5.0298   -5.1027   -4.9297   -4.8172
             0   -0.0865   -0.0865    0.1720
        5.1165    5.0162    5.1892    5.3333
       10.0596   10.0324   10.0324   10.1505
       15.0027   15.0486   14.9622   15.1398
       20.2060   19.9784   19.8919   20.1290
       24.9756   24.9081   24.8216   25.2043
       30.0054   29.9243   29.7514   29.8495];


    X.Cl=[    0.0048   -0.0143   -0.0833   -0.0391
        0.0048   -0.0117   -0.0729   -0.0162
        0.0044   -0.0095   -0.0584    0.0037
        0.0026   -0.0066   -0.0461    0.0155
        0.0022   -0.0037   -0.0297    0.0181
        0.0007   -0.0015   -0.0167    0.0185
       -0.0007    0.0022    0.0011         0
       -0.0037    0.0055    0.0160   -0.0185
       -0.0015    0.0099    0.0346   -0.0218
       -0.0048    0.0128    0.0517   -0.0144
       -0.0040    0.0158    0.0677    0.0015
       -0.0018    0.0190    0.0836    0.0170
        0.0015    0.0216    0.0918    0.0336];

    figure(28)
    S1=['bo-';'rs-';'gd-';'k^-'];
    S2=['bo';'rs';'gd';'k^'];
    for j=1:4
        h1=plot(R.betha(:,j)*180/pi,R.Cl(:,j),S1(j,:));
        set(h1,'Linewidth',2)
        hold on
        h2=plot(X.betha(:,j),X.Cl(:,j),S2(j,:));
        set(h2,'Linewidth',2)
    end

    grid on
    ylabel('Roll moment coefficient, C_l, [-]')
    xlabel('Angle of sideslip, \beta, [deg]')
    title('Effect of dihedral on Lift, AR=2.61 wing. Dihedral 0 deg.')
    legend('Tornado, \alpha = -0.4','Tornado, \alpha = 2.8','Tornado, \alpha = 15.2','Tornado, \alpha = 23.6',...
        'Experiment, \alpha = -0.4','Experiment, \alpha = 2.8','Experiment, \alpha = 15.2','Experiment, \alpha = 23.6')


    %Subploting planform
    wingx(1,:)=[0 0.25*geo.c+geo.b*tan(geo.SW)-0.25*geo.T*geo.c 0.25*geo.c+geo.b*tan(geo.SW)+0.75*geo.T*geo.c geo.c]./geo.c;
    wingy(1,:)=[0 geo.b*cos(geo.dihed) geo.b*cos(geo.dihed) 0]./geo.c;
    wingz(1,:)=[0 geo.b*sin(geo.dihed) geo.b*sin(geo.dihed) 0]./geo.c;


    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)

    h=plot(-wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)
    h=plot(wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)

    axis equal
    %axis off




%% Dihedral Validation TN1668 #3
case 13
%another testcase


    disp('Dihedral Validation TN1668 #2 -Roll moment, dihedral =10')

    cd(settings.acdir)
        load('NACATN1732');
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;
    geo.dihed=10*pi/180;


    alpha=[-0.7 2.4 14.9 23.2]*pi/180;
    for j=1:4

        state.alpha=alpha(j)

    betha=(-32:8:32)*pi/180;
    [kk void]=size(betha');
    for i=1:kk;    
    state.betha=betha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.betha(i,j)=state.betha;

        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end





    X.betha=[  -30.1227  -29.7203  -30.0373  -30.0426
      -25.1733  -24.7388  -25.1733  -24.9362
      -20.1387  -19.7573  -20.0533  -20.0000
      -15.1040  -14.7757  -15.0187  -14.9787
      -10.1547   -9.7942  -10.0693  -10.0426
       -5.0347   -4.8971   -4.8640   -4.9362
       -0.0853         0         0         0
        4.6933    4.8971    4.8640    4.6809
        9.8987    9.8786    9.6427    9.9574
       14.8480   14.6913   14.7627   14.8085
       19.7973   19.6728   19.7973   19.7447
       24.8320   24.5699   24.7467   24.8511
       29.6960   29.5515   29.7813   29.7872];


    X.Cl=[    -0.0384   -0.0611   -0.1106   -0.0409
       -0.0310   -0.0508   -0.0967   -0.0271
       -0.0220   -0.0393   -0.0817   -0.0138
       -0.0155   -0.0279   -0.0638   -0.0089
       -0.0090   -0.0176   -0.0411    0.0012
       -0.0024   -0.0074   -0.0211    0.0081
        0.0004         0    0.0008    0.0045
        0.0029    0.0098    0.0252    0.0036
        0.0086    0.0184    0.0496    0.0081
        0.0147    0.0246    0.0715    0.0170
        0.0212    0.0369    0.0923    0.0198
        0.0302    0.0492    0.1089    0.0344
        0.0384    0.0598    0.1228    0.0482];

    figure(29)
    S1=['bo-';'rs-';'gd-';'k^-'];
    S2=['bo';'rs';'gd';'k^'];
    for j=1:4
        h1=plot(R.betha(:,j)*180/pi,R.Cl(:,j),S1(j,:));
        set(h1,'Linewidth',2)
        hold on
        h2=plot(X.betha(:,j),X.Cl(:,j),S2(j,:));
        set(h2,'Linewidth',2)
    end



    grid on
    ylabel('Roll moment coefficient, C_l, [-]')
    xlabel('Angle of sideslip, \beta, [deg]')
    title('Effect of dihedral on Lift, AR=2.61 wing. Dihedral 10 deg.')
    legend('Tornado, \alpha = -0.7','Experiment, \alpha = -0.7','Tornado, \alpha = 2.4','Experiment, \alpha = 2.4','Tornado, \alpha = 14.9','Tornado, \alpha = 23.2','Experiment, \alpha = 14.9',...
        'Experiment, \alpha = 23.2')


    %Subploting planform
    wingx(1,:)=[0 0.25*geo.c+geo.b*tan(geo.SW)-0.25*geo.T*geo.c 0.25*geo.c+geo.b*tan(geo.SW)+0.75*geo.T*geo.c geo.c]./geo.c;
    wingy(1,:)=[0 geo.b*cos(geo.dihed) geo.b*cos(geo.dihed) 0]./geo.c;
    wingz(1,:)=[0 geo.b*sin(geo.dihed) geo.b*sin(geo.dihed) 0]./geo.c;


    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)

    h=plot(-wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)
    h=plot(wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)

    axis equal
    %axis off



%% Dihedral Validation TN1668 #3
case 14
    %another testcase
    disp('Dihedral Validation TN1668 #2 -Roll moment, dihedral =-10')

    cd(settings.acdir)
        load('NACATN1732');
        if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;
    geo.dihed=-10*pi/180;


    alpha=[0 3.1 15.6 23.8]*pi/180;
    for j=1:4

        state.alpha=alpha(j);

    betha=(-32:8:32)*pi/180;
    [kk void]=size(betha');
    for i=1:kk;    
    state.betha=betha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.betha(i,j)=state.betha;

        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end





    X.betha=[-30.0712  -30.4972  -30.3204  -29.8959
      -25.0740  -25.3702  -25.1934  -24.8986
      -20.0767  -20.4199  -20.1547  -19.9890
      -15.0795  -15.2928  -15.2928  -14.8164
       -9.9945  -10.1657  -10.0773  -10.0822
       -4.9973   -5.1271   -5.1271   -4.7342
       -0.0877   -0.2652   -0.0884    0.0877
        4.9096    4.5967    4.9503    5.0849
        9.9068    9.7238    9.8122    9.7315
       14.7288   14.8508   14.8508   15.0795
       19.9014   19.7127   19.8011   19.9014
       24.9863   24.7514   24.8398   25.0740
       29.8959   29.7901   29.9669   29.8082 ];


    X.Cl=[ 0.0414    0.0215   -0.0374   -0.0663
        0.0343    0.0152   -0.0348   -0.0577
        0.0257    0.0137   -0.0304    0.0157
        0.0175    0.0093   -0.0204    0.0266
        0.0112    0.0059   -0.0100    0.0210
        0.0034    0.0030   -0.0022    0.0090
       -0.0015   -0.0007    0.0048   -0.0067
       -0.0090   -0.0033    0.0104   -0.0221
       -0.0160   -0.0041    0.0196   -0.0270
       -0.0216   -0.0085    0.0244   -0.0172
       -0.0302   -0.0141    0.0315    0.0049
       -0.0377   -0.0207    0.0359    0.0315
       -0.0444   -0.0248    0.0396    0.0715];

    figure(30)
    S1=['bo-';'rs-';'gd-';'k^-'];
    S2=['bo';'rs';'gd';'k^'];
    for j=1:4
        h1=plot(R.betha(:,j)*180/pi,R.Cl(:,j),S1(j,:));
        set(h1,'Linewidth',2)
        hold on
        h2=plot(X.betha(:,j),X.Cl(:,j),S2(j,:));
        set(h2,'Linewidth',2)
    end

    grid on
    ylabel('Roll moment coefficient, C_l, [-]')
    xlabel('Angle of sideslip, \beta, [deg]')
    title('Effect of dihedral on Lift, AR=2.61 wing. Dihedral -10 deg.')
    legend('Tornado, \alpha = -0.4','Experiment, \alpha = -0.4','Tornado, \alpha = 2.8','Experiment, \alpha = 2.8','Tornado, \alpha = 15.2','Experiment, \alpha = 15.2','Tornado, \alpha = 23.6',...
        'Experiment, \alpha = 23.6')


    %Subploting planform
    wingx(1,:)=[0 0.25*geo.c+geo.b*tan(geo.SW)-0.25*geo.T*geo.c 0.25*geo.c+geo.b*tan(geo.SW)+0.75*geo.T*geo.c geo.c]./geo.c;
    wingy(1,:)=[0 geo.b*cos(geo.dihed) geo.b*cos(geo.dihed) 0]./geo.c;
    wingz(1,:)=[0 geo.b*sin(geo.dihed) geo.b*sin(geo.dihed) 0]./geo.c;


    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)

    h=plot(-wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)
    h=plot(wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)

    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    %axis off



%% Dihedral Validation TN1668 #3
case 15
    %another testcase
    disp('Dihedral Validation TN1668 #2 -Roll moment, dihedral =-20')

    cd(settings.acdir)
        load('NACATN1732');
                if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    %geo.nx=10;
    %geo.ny=15;
    geo.dihed=-20*pi/180;


    alpha=[0.6 3.7 16.2 24.4]*pi/180;
    for j=1:4

        state.alpha=alpha(j);

    betha=(-32:8:32)*pi/180;
    [kk void]=size(betha');
    for i=1:kk;    
    state.betha=betha(i);

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             
        [lattice,ref]=fLattice_setup2(geo,state,1);
        solverloop5(results,quest,JID,lattice,state,geo,ref);


        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.betha(i,j)=state.betha;

        R.CL(i,j)=results.CL;
        R.CD(i)=results.CD;
        R.Cm(i)=results.Cm;

        R.CY(i,j)=results.CY;
        R.Cn(i,j)=results.Cn;
        R.Cl(i,j)=results.Cl;

        R.CLL(i,:)=results.CL_local;
        R.YS(i,:)=results.ystation;

    end
    end

    X.betha=[-29.7656  -30.1554  -29.6060  -30.0752
      -24.8180  -25.1830  -24.6584  -25.0226
      -19.9501  -20.0501  -19.7107  -20.1303
      -14.9227  -15.3183  -14.9227  -15.0777
      -10.0549  -10.1855  -10.1347  -10.0251
       -4.8678   -4.8120   -4.8678   -5.0526
             0   -0.1604    0.1596   -0.5614
        5.1072    5.0526    5.1870    4.8120
        9.8155   10.0251   10.2145    9.7043
       14.9227   14.9975   14.8429   15.0777
       20.0299   19.9699   19.9501   20.0501
       24.8180   24.9424   25.0574   24.6216
       29.6858   29.7544   29.8454   29.8346];


    X.Cl=[     0.0741    0.0652    0.0148   -0.0243
        0.0619    0.0482    0.0072   -0.0239
        0.0460    0.0319    0.0011   -0.0192
        0.0327    0.0207    0.0007    0.0185
        0.0201    0.0120    0.0011    0.0159
        0.0090    0.0069    0.0014    0.0083
       -0.0004   -0.0011    0.0036    0.0007
       -0.0101   -0.0029    0.0051   -0.0120
       -0.0209   -0.0109    0.0072   -0.0217
       -0.0331   -0.0196    0.0101   -0.0192
       -0.0439   -0.0301    0.0058         0
       -0.0554   -0.0467    0.0036    0.0362
       -0.0665   -0.0598   -0.0014    0.0370];

    figure(31)
    S1=['bo-';'rs-';'gd-';'k^-'];
    S2=['bo';'rs';'gd';'k^'];
    for j=1:4
        h1=plot(R.betha(:,j)*180/pi,R.Cl(:,j),S1(j,:));
        set(h1,'Linewidth',2)
        hold on
        h2=plot(X.betha(:,j),X.Cl(:,j),S2(j,:));
        set(h2,'Linewidth',2)
    end

    grid on
    ylabel('Roll moment coefficient, C_l, [-]')
    xlabel('Angle of sideslip, \beta, [deg]')
    title('Effect of dihedral on Lift, AR=2.61 wing. Dihedral -10 deg.')
    legend('Tornado, \alpha = 0.6','Experiment, \alpha = 0.6','Tornado, \alpha = 3.7','Experiment, \alpha = 3.7','Tornado, \alpha = 16.2','Experiment, \alpha = 16.2','Tornado, \alpha = 24.4',...
        'Experiment, \alpha = 24.4')



    %Subploting planform
    wingx(1,:)=[0 0.25*geo.c+geo.b*tan(geo.SW)-0.25*geo.T*geo.c 0.25*geo.c+geo.b*tan(geo.SW)+0.75*geo.T*geo.c geo.c]./geo.c;
    wingy(1,:)=[0 geo.b*cos(geo.dihed) geo.b*cos(geo.dihed) 0]./geo.c;
    wingz(1,:)=[0 geo.b*sin(geo.dihed) geo.b*sin(geo.dihed) 0]./geo.c;


    axes('position',[0.55 0.14 0.3 0.3])
    h=plot(wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)
    hold on
    h=plot(-wingy(1,:),-wingx(1,:),'k');
    set(h,'Linewidth',3)

    h=plot(-wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)
    h=plot(wingy(1,:),wingz(1,:)+0.1,'k');
    set(h,'Linewidth',3)

    h = annotation('arrow',[0.7 0.7],[0.4 .2]);
    set(h,'Linewidth',2)

    axis equal
    %axis off





case 16
    disp('NACA0008 FLAP Airfoil comparison')

    cd(settings.acdir)
        load('NACA0010');
                if  isfield(geo,'allmove');
        else
            geo.allmove=            0;              %Allmoving surface set bit
            geo.allmove_origin=     [0 0 0]; %Origin of rotation for allmoving surface
            geo.allmove_axis=       [0 0 0];   %Hingeline for allmoving surface
            geo.allmove_symetric=    0;     %Symmetry for allmoving deflection
            geo.allmove_def=         0;          %Deflection of allmovin surface
        end
    cd(settings.hdir)

    cd(settings.sdir)
        load('teststate');
    cd(settings.hdir)

    xfoil=[0         0    0.1237    0.2446      0.3645  0.4871 0.61
        1.0000    0.1118    0.2327    0.3561    0.4747  0.5973 0.71
        2.0000    0.2236    0.3417    0.4674    0.5843  0.7073 0.82
        3.0000    0.3351    0.4506    0.5787    0.6933  0.8171 0.93
        4.0000    0.4465    0.5594    0.6897    0.8016  0.9267 1.04
        5.0000    0.5575    0.6681    0.8005    0.9095  1.036  1.15
        6.0000    0.6681    0.7767    0.9112    1.0160  1.145  1.27
        7.0000    0.7782    0.8851    1.0215    1.1219  1.25   1.37
        8.0000    0.8878    0.9937    1.1317    1.2270  1.36   1.48
        9.0000    0.9968    1.1016    1.2415    1.3311  1.47   1.59
       10.0000    1.1050    1.2095    1.3511    1.4342  1.57   1.7 ]; 


    alpha=(0:1:10)*pi/180;
    geo.flapped=1;
    geo.fc=0.2;
    geo.fnx=10;

    def=[0 2 4 6 8 10]*pi/180;

    for j=1:6
        geo.flap_vector=def(j)
    for i=1:10
        state.alpha=alpha(i);

        geo.nx=30;  
        geo.meshtype=3;

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
        JID='batchjob';             

        [lattice,ref]=fLattice_setup2(geo,state,0);
        solverloop5(results,quest,JID,lattice,state,geo,ref);

        cd(settings.odir)
            load batchjob-Cx;
        cd(settings.hdir)

        R.alpha(i,j)=state.alpha;
        R.CL(i,j)=results.CL;
        R.Cm(i,j)=results.Cm;    
    end

    end
        plot(R.alpha*180/pi,R.CL)
        hold on
        h=plot(xfoil(:,1),xfoil(:,2),'r-.');
        h=plot(xfoil(:,1),xfoil(:,3),'r-.'); 
        h=plot(xfoil(:,1),xfoil(:,4),'r-.');
        h=plot(xfoil(:,1),xfoil(:,5),'r-.');
        h=plot(xfoil(:,1),xfoil(:,6),'r-.');
        h=plot(xfoil(:,1),xfoil(:,7),'r-.');
        xlabel('Angle of attack, \alpha, [deg]')
        ylabel('Liftcoefficient, C_L, [-]')
        legend('0','2','4','6','8','10','XFOIL')

        
 case 17
 disp('NACA TND4888 Propeller comparison')

    cd(settings.acdir)
        load('TND4448_S2_v2');
    cd(settings.hdir)
        cd(settings.sdir)
        load('propvalstate');
    cd(settings.hdir)

    
    %[Tc' RPM'./1000 T'./1000]
    %1.0000    0.9308    7.4970
    %2.5000    1.3085   18.7425
    %3.9000    1.5423   29.2383
    %4.9000    1.7246   36.7353
        
        S_ref=30.53;
    
        CT=S_ref*0.5*state.rho*state.AS^2;
        T=[1 1 1 1
        4.9 4.9 4.9 4.9]*CT;
    
   
      RPM=[0.9308 0.9308 0.9308 0.9308
        1.7246 1.7246 1.7246 1.7246]*1000;  



P2=[   -8.2918   -0.3659
   -4.0688   -0.1194
    0.0119    0.1272
    4.2823    0.3738
    8.4104    0.6438
   12.8233    0.9843
   16.9988    1.2427
   18.8968    1.3718
   20.8897    1.4540
   22.9300    1.4188
   24.9229    1.4658
   27.0581    1.4423
   29.0036    1.4775];   %Thrust coefficient 0

P3=[   -8.4379   -0.6228
   -4.2249   -0.1749
   -0.0592    0.2024
    4.3432    0.6385
    8.6509    1.0982
   12.8639    1.5697
   17.3609    2.0884
   19.4438    2.2888
   21.5266    2.3595
   23.4675    2.5363
   25.7396    2.6660
   27.8698    2.6778]; %Thrust coefficient 1

P4=[   -9.0985   -1.3536
   -4.4009   -0.3752
    0.1068    0.5442
    4.6145    1.2043
    9.0747    1.9587
   14.0095    3.1375
   19.1815    3.9980
   20.8422    4.6228
   23.0724    4.7996
   25.3025    5.1061
   27.3903    5.1297]; %Thrust coefficient 4.9

alpha=(-10:2:25)*pi/180;

for i=1:3
    
    if i==1
        cd(settings.acdir)
            load('TND4448_S1');     %Without prop
        cd(settings.hdir)
        
    end
    if i>1
        cd(settings.acdir)
            load('TND4448_S2_v2');
        cd(settings.hdir)
        
        geo.prop.T=T(i-1,:);
        geo.prop.rpm=RPM(i-1,:);
    end
    
    geo.nx=10;
    geo.ny=20;    
    

  








    for j=1:18
        state.alpha=alpha(j);
        %state.alpha=14*pi/180;

        quest=1;                    %Simple state solution, could be something else
        results=[];                 %but then you'll have to change below too
                   

        [lattice,ref]=fLattice_setup2(geo,state,1);        
        %geometryplot(lattice,geo,ref);
        
        [results]=solver9(results,state,geo,lattice,ref);
        [results]=coeff_create3(results,lattice,state,ref,geo);
        
        
        
        
       

        
        %ZZZ(results,lattice,geo,ref,state)

        R.alpha(i,j)=state.alpha;
        R.CL(i,j)=results.CL;
        R.Cm(i,j)=results.Cm;
        
        %% Testing wake strength
%         P=geo.prop.pos(1,:)+[2*geo.prop.dia(1) 0 0];
%         profile=P+[zeros(21,1) zeros(21,1) [0:0.05:1]'*geo.prop.dia(1)/2*1.3]
%         
%         wash=propwash(lattice.prop,profile);
%         figure(1702)
%         plot(wash(:,1),profile(:,3))
        
        
    end
end
figure(1701)
plot(R.alpha(1,:)*180/pi,R.CL(1,:))
hold on
plot(R.alpha(2,:)*180/pi,R.CL(2,:),'--')
plot(R.alpha(3,:)*180/pi,R.CL(3,:),'-.')

plot(P2(:,1),P2(:,2),'o')
plot(P3(:,1),P3(:,2),'^')
plot(P4(:,1),P4(:,2),'d')


end  
