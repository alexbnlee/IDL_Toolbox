PRO China_PAR_from_Global_nc, path_input, path_output

  ;针对netcdf数据实现全球PAR-光合有效辐射的中国海区的切割
  ;并将像元的经纬度信息作为变量包含进去
  ;编写日期 :2018-01-15
  ;修订日期 :2018-01-15    针对2016年以后数据的定标参数与以前不同，将固定定标参数修正了根据属性自动定标计算


  ;最好有个局域网链接测试代码
  MyRootDir=path_input   ;磁盘阵列对应地址
  files = FILE_SEARCH(MyRootDir+'\*.nc',count=num);





  ;****首先要了解MODIS 4km产品的网格特点，其全球产品大小为 [8640, 4320]
  ;    网格点经纬度步长为0.0416667，左下角点的经度为-180加上半个步长大小（即 -179.97917）
  ;    左下角纬度为90减去个步长大小   （即 89.979164）  注：图像倒置的

  step=0.0416667d

  lat=FLTARR(648,577)    ;529------------->648,增119像元
  lon=FLTARR(648,577)
  FOR j=0L,576 DO lat[0,j]=41.145790-j*step
  FOR j=0L,647 DO lat[j,*]=lat[0,*]
  ; tvscl,lat

  FOR i=0L,647 DO lon[i,0]=105.14607+i*step
  FOR i=0L,576 DO lon[*,i]=lon[*,0]
  ;  tvscl,lon





  IF num GT 0 THEN BEGIN   ;计算平均值
    PRINT,'the number of SST files is',num
    PRINT,files
    FOR i=0,num-1 DO BEGIN

      nid = NCDF_OPEN(files[i], /nowrite )
      sstid = NCDF_VARID(nid, 'par')
      ncdf_attget,nid,sstid,'scale_factor',scale_factor   ;或者变量sst里名为scale_factor的属性，存放如scale_factor中
      ncdf_attget,nid,sstid,'add_offset',add_offset   ;或者变量sst里名为add_offset的属性，存放如add_offset中

      ; NCDF_VARGET, nid, latitude_id,latitude

      NCDF_VARGET, nid, sstid, sst
      sst=sst[6843:7490,1172:1748]
      sst=sst*scale_factor+add_offset

      NCDF_CLOSE,nid


      ;      att0name=hdf_sd_attdir(hdfid,varname[0]) ;获得第1个变量的属性名

      ;      hdf_sd_attread,hdfid,varname[0],att0name[3],intercept  ;获取线性关系的截距
      ;      hdf_sd_attread,hdfid,varname[0],att0name[2],slope   ;获取线性关系的斜率
      ;      print,intercept
      PRINT,i

      PRINT,MAX(sst)
      ;      dis=where((sst ge -5.0) and (sst lt 40.0))
      ;      print,min(sst)


      fn=FILE_BASENAME(files[i],'.nc')
      fp=path_output
      fn_new=fp+'\'+fn+'_China.hdf'

      hdfid2=HDF_SD_START(fn_new,/creat)
      varid=HDF_SD_CREATE(hdfid2,'SST',[648,577],/float)
      varid1=HDF_SD_CREATE(hdfid2,'Latitude',[648,577],/float)
      varid2=HDF_SD_CREATE(hdfid2,'Longitude',[648,577],/float)
      HDF_SD_ADDDATA,varid,sst
      HDF_SD_ADDDATA,varid1,lat
      HDF_SD_ADDDATA,varid2,lon
      HDF_SD_ENDACCESS,varid
      HDF_SD_ENDACCESS,varid1
      HDF_SD_ENDACCESS,varid2
      HDF_SD_END,hdfid2

    ENDFOR
  ENDIF

  PRINT,MAX(sst)
  PRINT,MIN(sst)

END