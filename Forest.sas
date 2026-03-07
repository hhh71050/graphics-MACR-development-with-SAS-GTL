/*=============================================================================
                            Environment Information
-------------------------------------------------------------------------------
 SAS Version            : 9.4 under Windows 10
-------------------------------------------------------------------------------
                            Purpose
-------------------------------------------------------------------------------
 Define Forest Plot template with SAS GTL.
-------------------------------------------------------------------------------
                            GTL dynamic or mvar Description
-------------------------------------------------------------------------------
 _obs: display order (reversed), used as y-axis
 _effect: the descriptions for subgroups and effects within them
 _low, _hi: the lower, upper confidence limit of point estimate
 _point: the Point Estimate, e.g, Odds/Hazard Ratio, Risk Difference (%) 
 _Pval: test of Wald statistic value z (z = coef/se(coef)). to evaluates whether
        the beta (¦Â) coefficient of a subgroup is significantly different from 0
        or the estimate ratio of a effect within is significantly different from 1
        (a small pvalue indicate yes)
 _yRefLn: use to block rows of a variable/parameter for interphase display
 PtLabl: optional, the label that put as high-low graphic's header, default is
         the column label of _point 
 RBtxt, LBtxt: text on bottom, both besides of referenceline where x=_xRefLn to
               explain prognostic (good or bad)
-------------------------------------------------------------------------------
                            Programmer Information
-------------------------------------------------------------------------------
 Author                 : Houhui Hu                                Copyright(c)
 Creation Date          : 06-09 DEC2022
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
  define statgraph Graphics.Forest;
  dynamic _obs _effect _layer _low _hi _point _xRefLn _EstCl _Pval _yRefLn;
  mvar PtLabl LBtxt RBtxt thick;
  begingraph;
    discreteattrmap name='grpmap' /ignorecase=true;
      value '0' /textattrs=(size=8 weight=bold);
      value '1' /textattrs=(size=7 weight=normal);
    enddiscreteattrmap;
    discreteattrvar attrvar=grpMarkers var=_layer attrmap='grpmap';
    layout overlay /walldisplay=none
                    xaxisopts=(display=(line ticks tickvalues) type=log
                               logopts=(base=10 valuestype=expanded
                               tickintervalstyle=logexpand minorticks=true))
                    x2axisopts=(display=(label) label=(PtLabl))
                    yaxisopts=(reverse=true display=none);
      referenceline y=_yRefLn /yaxis=Y lineattrs=(thickness=thick color=CXF0F0F0);
      highlowplot y=_obs low=_low high=_hi /type=line highcap=serif lowcap=serif;
      scatterplot x=_point y=_obs;
      scatterplot x=_point y=_obs /xaxis=X2 markerattrs=(size=0);
      referenceline x=_xRefLn /xaxis=X;
      innermargin /align=left;
        axistable y=_obs value=_effect /indentweight=_layer textgroup=grpMarkers
                                        labeljustify=left;
      endinnermargin;
      innermargin /align=right;
        axistable y=_obs value=_EstCl /labeljustify=left;
        axistable y=_obs value=_Pval /labeljustify=left;
      endinnermargin;
      entry halign=left LBtxt /valign=bottom;
      entry halign=right RBtxt /valign=bottom;
    endlayout;
  endgraph;
  end;
run;
