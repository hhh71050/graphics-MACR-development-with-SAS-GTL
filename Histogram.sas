/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define Histogram Plot template with SAS GTL.
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 18- FEB2023
-------------------------------------------------------------------------------
                            Change Control Information
-------------------------------------------------------------------------------
 Modifications:
 Programmer/Date:       Reason:
 ----------------       -----------------------------------------------------

-------------------------------------------------------------------------------
                            Future
-------------------------------------------------------------------------------

==============================================================================*/

proc template;
define statgraph Graphics.Histogram;
  dynamic _x _y _grp _byline_;
  mvar footer;
  nmvar MinDT MaxDT;
  begingraph;
    entrytitle 'Histogram for ' eval(collabel(_y));
    entrytitle _byline_;
    if (exists(footer))
        entryfootnote halign=left footer;
    endif;
    layout overlay /xaxisopts=(display=(ticks tickvalues)
                               timeopts=(viewmin=MinDT viewmax=MaxDT));
      histogramparm x=_x y=_y /name='histogram' group=_grp;
      discretelegend 'histogram' /halign=right valign=top
                                  across=1 location=inside;
    endlayout;
  endgraph;
end;
run;

libname tst 'C:\Users\huhouhui\Desktop\tst\Graphics';

proc sql noprint;
  select min(date)-7, max(date)+7
  into :MinDT trimmed, :MaxDT trimmed from tst.enroll;
quit;
%put |&MinDT|&MaxDT|;

proc sgrender data=tst.enroll template=Graphics.Histogram;
  dynamic _x='date' _y='count' _grp='group';
run;
