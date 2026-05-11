%macro _process_interact_files(Loc=, File=, Type=, Data=);
    %local FullPath;
    %let FullPath = &Loc&dlm&File;

    %if ^%sysfunc(fileexist("&FullPath")) %then %do;
        /* 如果文件不存在，生成模板 */
        ods excel file="&FullPath";
        %if &Type = TmOpt %then %do;
            proc sql;
                create table _PreTmOpt as
                select distinct &by, 
                       max(&time) as MaxTm, 
                       round(max(&time)/10) as TmBy 
                from &Data 
                group by &by;
            quit;
            proc print data=_PreTmOpt noobs; run;
        %end;
        %else %if &Type = AttrMap %then %do;
            /* 生成属性映射模板 */
            proc sql;
                create table _PreAttr as
                select distinct "&strata" as ID, &strata as Value,
                       "" as LineColor, "" as MarkerColor, "" as LinePattern
                from &Data;
            quit;
            proc print data=_PreAttr noobs; run;
        %end;
        ods excel close;
    %end;

    /* 导入已经存在或刚刚生成的 Excel 文件 */
    proc import datafile="&FullPath" dbms=xlsx out=&Type replace; 
        getnames=yes; 
    run;
%mend _process_interact_files;

%macro _prepare_plot_data();
    /* 处理分层标签 */
    data _SurvPlot;
        set _SurvPlot0;
        %if &strata ne %then %do;
            /* 提取分层变量的真实值（处理 lifetest 自动添加的冒号） */
            &strata = strip(scan(&strata, 2, ':'));
            label &strata = "&StraLabl";
        %end;
    run;

    /* 处理中位数标记 */
    data _median;
        set _Quartiles;
        where Percent=50 and ^missing(Estimate);
        median = Estimate;
        prob = 0.5;
        keep %if &strata ne %then &strata; median prob;
    run;

    /* 检查是否存在中位数数据，供渲染动态调用 */
    %let dsid = %sysfunc(open(_median));
    %let haveMedian = %sysfunc(attrn(&dsid, nobs));
    %let rc = %sysfunc(close(&dsid));

    /* 如果有分层，处理 Log-Rank 检验 P 值 */
    %if &strata ne %then %do;
        data _null_;
            set _HomTests;
            if _n_=1 then call symputx('LogRnkP', put(ProbChiSq, pvalue6.4));
        run;
    %end;

    /* 最终数据合并 */
    proc sort data=_SurvPlot; %if &strata ne %then by &strata;; run;
    proc sort data=_median;   %if &strata ne %then by &strata;; run;

    data _by_curr;
        merge _SurvPlot _median;
        %if &strata ne %then %do;
            by &strata;
            if ^first.&strata then call missing(median, prob);
        %end;
        %else %do;
            if _n_ > 1 then call missing(median, prob);
        %end;
    run;
%mend _prepare_plot_data;
