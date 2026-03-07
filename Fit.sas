
proc template;
define statgraph Graphics.Fit;
  dynamic _x _y _grp _by;
  mvar byval obs ErrDF MSE rsq AdjRsq;
  begingraph;
    entrytitle 'Regression Fit Plot for ' eval(collabel(_y));
    if (exists(_by))
      entrytitle eval(collabel(_by)) ' = ' byval;
    endif;
    layout overlay;
      modelband 'clm' /name='clm' legendlabel='95% CLM'
                       group=eval(dsort(_grp, retain=all));
      modelband 'cli' /name='cli' legendlabel='95% CLI'
                       display=(outline) outlineattrs=(pattern=dash)
                       group=eval(dsort(_grp, retain=all));
      scatterplot x=_x y=_y /group=eval(dsort(_grp, retain=all));
      regressionplot x=_x y=_y /name='fitline' legendlabel='Regression Fit'
                     clm='clm' cli='cli' group=eval(dsort(_grp, retain=all));
      discretelegend 'fitline' 'clm' 'cli';
      if (exists(obs)|exists(ErrDF)|exists(MSE)|exists(rsq)|exists(AdjRsq))
        layout gridded /autoalign=(topleft topright bottomleft bottomright)
                        columns=1 border=true shrinkFonts=true;
          if (exists(obs))
            entry halign=left 'Observations' halign=right obs;
          endif;
          if (exists(ErrDF))
            entry halign=left 'Error DF' halign=right ErrDF;
          endif;
          if (exists(MSE))
            entry halign=left 'MSE' halign=right MSE;
          endif;
          if (exists(rsq))
            entry halign=left 'R-Square' halign=right rsq;
          endif;
          if (exists(AdjRsq))
            entry halign=left 'Adj R-Sq' halign=right AdjRsq;
          endif;
        endlayout;
      endif;
    endlayout;
  endgraph;
end;
quit;
