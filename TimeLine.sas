
proc template;
define statgraph Graphics.TimeLine;
  dynamic _by _topic _StDt _StDy _EnDy _grp _LowLabl _HighCap;
  mvar byval GrpLabl;
  nmvar MaxDurd MinDT MaxDT;
  begingraph;
    /*
    discreteattrmap name='Severity' /DiscreteLegendEntryPolicy=attrmap;
      value 'Mild' /fillattrs=(color=lightgreen);
      value 'Moderate' /fillattrs=(color=gold);
      value 'Severe' /fillattrs=(color=darkred);
    enddiscreteattrmap;
    discreteattrvar attrmap='Severity' attrvar=SevMap var=_grp;
    */
    if (exists(_by))
      entrytitle halign=center 'Timeline Plot for ' eval(collabel(_by)) ' of ' byval;
    endif;
    layout lattice;
      layout overlay /xaxisopts=(display=(line ticks tickvalues) griddisplay=on
                                 linearopts=(viewmin=0 viewmax=MaxDurd))
                      x2axisopts=(display=(ticks tickvalues)
                                  timeopts=(viewmin=MinDT viewmax=MaxDT))
                      yaxisopts=(reverse=true display=(line)
                                 discreteopts=(tickvaluefitpolicy=none));
        highlowplot y=_topic low=_StDy high=_EnDy
                   /name='HighlowBar' type=bar barwidth=.4
                    HighCap=_HighCap groupdisplay=overlay group=_grp /*SevMap*/
                    LowLabel=_LowLabl labelattrs=(color=black)
                    ;
        scatterplot x=_StDt y=_topic /xaxis=X2 markerattrs=(size=0);
        referenceline x=0 /xaxis=X;
      endlayout;
      if (exists(_grp))
        sidebar /align=bottom spacefill=false;
          discretelegend 'HighlowBar' /title=GrpLabl;
        endsidebar;
      endif;
    endlayout;
  endgraph;
end;
run;
