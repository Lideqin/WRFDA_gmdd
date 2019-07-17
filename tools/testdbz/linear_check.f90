program linear_check

implicit none

integer,parameter             :: nx=449,ny=449,nz=42
real,dimension(nx,ny,nz)      :: p,tc,qv,qi,qc,qr,qs,qg,nr,ns,ng
real,dimension(nx,ny,nz)      :: dqr,dqs,dqg,dnr,dns,dng,dtc,dqv
real,dimension(nx,ny,nz)      :: dbz_org,dbz_prt,zmm_org,zmm_prt
real,dimension(nx,ny,nz)      :: dbz_lin,zmm_lin

real,dimension(nx,ny,nz)      :: tc_org,qv_org,qr_org,qs_org,qg_org
real,dimension(nx,ny,nz)      :: tc_prt,qv_prt,qr_prt,qs_prt,qg_prt

real,dimension(nx,ny,nz)      :: dbz_grd,zmm_grd

real                          :: rn0_r,rn0_s,rn0_g
real                          :: rhos,rhog

integer                       :: tlopt0=2,tlopt
integer                       :: gropt0=2,gropt
integer                       :: keepconstopt=234  ! 1 rho is constant during minimization
                                                 ! 2 F (fraction) is constant during minimization
                                                 ! 3 SD of the canting angle for hail is constant during minimization
												 ! 4 rhom is constatnt
						                         ! 12 denotes the combination of 1 & 2, so does the 13,and 23,234
integer                       :: i,j,k
real,dimension(nx,ny,nz)      :: temra01,temra02,temra03

integer                       :: ivar,seed
real                          :: stdt,stdqv,stdqr,stdqs,stdqg
real                          :: ratio ! sum[h(x+dx)-H(dx)]/sum[h(x)]
real                          :: ratio2 ! sum(h(x+dx)-h(x))/sum(H(dx))
real                          :: mag_std
real                          :: min_mag=1e-5,mag_int
integer                       :: is,ie,js,je,ks,ke
integer                       :: print_lvl=5
real                          :: mag_thres=0.00
integer                       :: print_init
integer                       :: radii=100
integer                       :: seed_init=200

integer                       :: count_neg_right,count_neg_wrong
integer                       :: count_pos_right,count_pos_wrong
real                          :: temr01,temr02,temr03,temr04,temr05

real                          :: grd_chk_lt,grd_chk_rt  !! left <y,y> right <x,(A*)y> 

character(len=256)            :: diagfilename
character(len=128)            :: wrtfmt
integer                       :: icount
character(len=1)              :: temc1_01

!----------------------------------------------------
!    begin executable codes
!---------------------------------------------------

rn0_r=8e6
rn0_s=3e6
rn0_g=4e5
rhos=100.0
rhog=400.0
print_init=1
mag_std=1.0

write(temc1_01,'(I1)') tlopt0
diagfilename="dbzdata_tlopt"//temc1_01
open(1234,file=trim(diagfilename)//'.dat',form='binary')

icount=0
print*,"test begin"
do while(mag_std>=min_mag)
stdt =1.e-2*mag_std*0
stdqv=1.e-2*mag_std*0
stdqr=1.e-3*mag_std
stdqs=1.e-3*mag_std
stdqg=1.e-3*mag_std

if(print_lvl>=10)print*,"stdt,stdqv,stdqr,stdqs,stdqg"
if(print_lvl>=10)print*, stdt,stdqv,stdqr,stdqs,stdqg

call readdata()

!stop("test data input")

p=p*100.0
tc=tc+273.15
qr=qr
qs=qs
qg=qg

nr=0
ns=0
ng=0

dqr=0
dqs=0
dqg=0
dnr=0
dns=0
dng=0
dtc=0
dqv=0
dbz_org=0
zmm_org=0
dbz_prt=0
dbz_lin=0
zmm_prt=0
zmm_lin=0

tc_prt=0
qv_prt=0
qr_prt=0
qs_prt=0
qg_prt=0

is=250  !nx/2-radii
ie=300  !nx/2+radii
js=200  !ny/2-radii
je=250  !ny/2+radii
ks=1
ke=30

!open (1111,file='wrfdata.dat',form='binary')
!write(1111) p (is:ie,js:je,ks:ke)
!write(1111) tc(is:ie,js:je,ks:ke)
!write(1111) qv(is:ie,js:je,ks:ke)
!write(1111) qc(is:ie,js:je,ks:ke)
!write(1111) qi(is:ie,js:je,ks:ke)
!write(1111) qr(is:ie,js:je,ks:ke)
!write(1111) qs(is:ie,js:je,ks:ke)
!write(1111) qg(is:ie,js:je,ks:ke)
!close(1111)
!stop
if(print_init==1) print('(A,E12.5)'),"qr mean",sum(qr(is:ie,js:je,ks:ke))/((ie-is+1)*(je-js+1)*(ke-ks+1))
if(print_init==1) print('(A,E12.5)'),"qs mean",sum(qs(is:ie,js:je,ks:ke))/((ie-is+1)*(je-js+1)*(ke-ks+1))
if(print_init==1) print('(A,E12.5)'),"qg mean",sum(qg(is:ie,js:je,ks:ke))/((ie-is+1)*(je-js+1)*(ke-ks+1))

print_init=0

if(print_lvl>=10) print*,"calc original dbz"
tc_org=tc
qv_org=qv
qr_org=qr
qs_org=qs
qg_org=qg

tlopt=0
gropt=0
do k=ks,ke
  do j=js,je
    do i=is,ie
      call oudbzcalc_lin(qv(i,j,k),qr(i,j,k),qs(i,j,k),qg(i,j,k),nr(i,j,k),           &
                         ns(i,j,k),ng(i,j,k),tc(i,j,k),p(i,j,k),dbz_org(i,j,k),       &
                         1,1,1,0,0,0,rn0_r,rn0_s,rn0_g,                               &
                         rhos,rhog,dtc(i,j,k),dqv(i,j,k),dqr(i,j,k),dqs(i,j,k),dqg(i,j,k),                  &
                         dnr(i,j,k),dns(i,j,k),dng(i,j,k),zmm_org(i,j,k),             &
                         tlopt,gropt,i,j,k,zmm_org(i,j,k),keepconstopt)
    enddo
  enddo
enddo
if(print_lvl>=10) print*,"done calc original dbz"
if(print_lvl>=10) print*,"dbz max min",maxval(maxval(maxval(dbz_org(is:ie,js:je,ks:ke),1),1),1) &
                    ,minval(minval(minval(dbz_org(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=10) print*,"------------------------------------------------"
if(print_lvl>=10) print*,"add perturbation"
do ivar=1,5
  seed=-seed_init-ivar
  do k=ks,ke
    do j=js,je
      do i=is,ie
         if(ivar==1.and.1==0) then
           tc_prt(i,j,k)=GASDEV(seed)*tc(i,j,k)*mag_std*0.1 !stdt
           tc(i,j,k)=tc(i,j,k)+tc_prt(i,j,k)
         endif
         if(ivar==2.and.1==0) then
           qv_prt(i,j,k)=GASDEV(seed)*qv(i,j,k)*mag_std   !stdqv  
           if(qv(i,j,k)+qv_prt(i,j,k)<0.) qv_prt(i,j,k)=-qv(i,j,k)
           qv(i,j,k)=qv(i,j,k)+qv_prt(i,j,k)
         endif
         if(ivar==3.and.qr(i,j,k)>stdqr*mag_thres) then
           qr_prt(i,j,k)=GASDEV(seed)*qr(i,j,k)*mag_std  !stdqr          
         !  if(tc(i,j,k)-273.15<=-1.0) qr_prt(i,j,k)=0.0
           if(qr(i,j,k)+qr_prt(i,j,k)<0.) qr_prt(i,j,k)=-qr(i,j,k)
           qr(i,j,k)=qr(i,j,k)+qr_prt(i,j,k)
         endif 
         if(ivar==4.and.qs(i,j,k)>stdqs*mag_thres) then
           qs_prt(i,j,k)=GASDEV(seed)*qs(i,j,k)*mag_std  !stdqs
         !  if(tc(i,j,k)-273.15>=10.0) qs_prt(i,j,k)=0.0          
           if(qs(i,j,k)+qs_prt(i,j,k)<0.) qs_prt(i,j,k)=-qs(i,j,k)
           qs(i,j,k)=qs(i,j,k)+qs_prt(i,j,k)
         endif
         if(ivar==5.and.qg(i,j,k)>stdqg*mag_thres) then
           qg_prt(i,j,k)=GASDEV(seed)*qg(i,j,k)*mag_std  !stdqg          
           if(qg(i,j,k)+qg_prt(i,j,k)<0.) qg_prt(i,j,k)=-qg(i,j,k)
           qg(i,j,k)=qg(i,j,k)+qg_prt(i,j,k)
         endif
      enddo
    enddo
  enddo
enddo

if(print_lvl>=1) print*,"tc_prt max min",maxval(maxval(maxval(tc_prt(is:ie,js:je,ks:ke),1),1),1) &
                       ,minval(minval(minval(tc_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=1) print*,"qv_prt max min",maxval(maxval(maxval(qv_prt(is:ie,js:je,ks:ke),1),1),1) &
                       ,minval(minval(minval(qv_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=1) print*,"qr_prt max min",maxval(maxval(maxval(qr_prt(is:ie,js:je,ks:ke),1),1),1) &
                       ,minval(minval(minval(qr_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=1) print*,"qs_prt max min",maxval(maxval(maxval(qs_prt(is:ie,js:je,ks:ke),1),1),1) &
                       ,minval(minval(minval(qs_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=1) print*,"qg_prt max min",maxval(maxval(maxval(qg_prt(is:ie,js:je,ks:ke),1),1),1) &
                       ,minval(minval(minval(qg_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=1) print*,"done adding perturbation"
if(print_lvl>=1) print*,"------------------------------------------------"

if(print_lvl>=10) print*,"calc pert dbz"
tlopt=0
gropt=0
dqr=qr_prt
dqs=qs_prt
dqg=qg_prt
dqv=qv_prt
dtc=tc_prt
do k=ks,ke
  do j=js,je
    do i=is,ie
      call oudbzcalc_lin(qv(i,j,k),qr(i,j,k),qs(i,j,k),qg(i,j,k),nr(i,j,k),           &
                         ns(i,j,k),ng(i,j,k),tc(i,j,k),p(i,j,k),dbz_prt(i,j,k),       &
                         1,1,1,0,0,0,rn0_r,rn0_s,rn0_g,                               &
                         rhos,rhog,dtc(i,j,k),dqv(i,j,k),dqr(i,j,k),dqs(i,j,k),dqg(i,j,k),                  &
                         dnr(i,j,k),dns(i,j,k),dng(i,j,k),zmm_prt(i,j,k),             &
                         tlopt,gropt,i,j,k,zmm_prt(i,j,k),keepconstopt)
    enddo
  enddo
enddo
if(print_lvl>=10) print*,"done calc pert dbz"
if(print_lvl>=10) print*,"dbz max min",maxval(maxval(maxval(dbz_prt(is:ie,js:je,ks:ke),1),1),1) &
                    ,minval(minval(minval(dbz_prt(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=10) print*,"------------------------------------------------"


if(print_lvl>=10) print*,"calc tangent linear dbz (increment)"
dqr=qr_prt
dqs=qs_prt
dqg=qg_prt
dqv=qv_prt
dtc=tc_prt
zmm_lin=zmm_org
tlopt=tlopt0
gropt=0
count_neg_right=0
count_pos_right=0
count_neg_wrong=0
count_pos_wrong=0
do k=ks,ke
  do j=js,je
    do i=is,ie
      call oudbzcalc_lin(qv_org(i,j,k),qr_org(i,j,k),qs_org(i,j,k),qg_org(i,j,k),nr(i,j,k),           &
                         ns(i,j,k),ng(i,j,k),tc_org(i,j,k),p(i,j,k),dbz_lin(i,j,k),                   &
                         1,1,1,0,0,0,rn0_r,rn0_s,rn0_g,                                           &
                         rhos,rhog,dtc(i,j,k),dqv(i,j,k),dqr(i,j,k),dqs(i,j,k),dqg(i,j,k),                              &
                         dnr(i,j,k),dns(i,j,k),dng(i,j,k),zmm_lin(i,j,k),                         &
                         tlopt,gropt,i,j,k,zmm_prt(i,j,k),keepconstopt)

      !if(abs((zmm_org(i,j,k)+zmm_lin(i,j,k)-zmm_prt(i,j,k))/(zmm_org(i,j,k)-zmm_prt(i,j,k)))<=1.0.and.zmm_lin(i,j,k)<0.0) count_neg_right=count_neg_right+1
      !if(abs((zmm_org(i,j,k)+zmm_lin(i,j,k)-zmm_prt(i,j,k))/(zmm_org(i,j,k)-zmm_prt(i,j,k)))<=1.0.and.zmm_lin(i,j,k)>0.0) count_pos_right=count_pos_right+1
      !if(abs((zmm_org(i,j,k)+zmm_lin(i,j,k)-zmm_prt(i,j,k))/(zmm_org(i,j,k)-zmm_prt(i,j,k)))> 1.0.and.zmm_lin(i,j,k)<0.0) count_neg_wrong=count_neg_wrong+1
      !if(abs((zmm_org(i,j,k)+zmm_lin(i,j,k)-zmm_prt(i,j,k))/(zmm_org(i,j,k)-zmm_prt(i,j,k)))> 1.0.and.zmm_lin(i,j,k)>0.0) count_pos_wrong=count_pos_wrong+1

    enddo
  enddo
enddo
write(1234) zmm_org(is:ie,js:je,ks:ke)
write(1234) zmm_prt(is:ie,js:je,ks:ke)
write(1234) zmm_lin(is:ie,js:je,ks:ke)
write(1234) dbz_org(is:ie,js:je,ks:ke)
write(1234) dbz_prt(is:ie,js:je,ks:ke)
write(1234) dbz_lin(is:ie,js:je,ks:ke)

!if(print_lvl>=5) print*,"count_neg_right,count_neg_wrong,count_pos_right,count_pos_wrong",count_neg_right,count_neg_wrong,count_pos_right,count_pos_wrong, &
!                                                                                          count_neg_right/count_neg_wrong,count_pos_right/count_pos_wrong
if(print_lvl>=10) print*,"done calc tangent linear dbz (increment)"
if(print_lvl>=10) print*,"dbz max min",maxval(maxval(maxval(dbz_lin(is:ie,js:je,ks:ke),1),1),1) &
                    ,minval(minval(minval(dbz_lin(is:ie,js:je,ks:ke),1),1),1)
if(print_lvl>=10) print*,"------------------------------------------------"

!--------------------------------------------------------------
!stop("test tangent linear only")
!--------------------------------------------------------------


if(print_lvl>=10) print*,"dbz ratio"
ratio=sum(abs(dbz_prt(is:ie,js:je,ks:ke)-dbz_lin(is:ie,js:je,ks:ke)))/sum(abs(dbz_org(is:ie,js:je,ks:ke)))
!ratio2=sum(abs(dbz_prt(is:ie,js:je,ks:ke)-dbz_org(is:ie,js:je,ks:ke)))/sum(abs(dbz_lin(is:ie,js:je,ks:ke)))
temr01=0
temr02=0
temr03=0
!print*,"newtest"
do k=ks,ke
  do j=js,je
    do i=is,ie
	   if(abs(dbz_prt(i,j,k)-dbz_org(i,j,k))>0.0.and.abs(dbz_lin(i,j,k))>0.0) then
	     temr01=temr01+abs(dbz_prt(i,j,k)-dbz_org(i,j,k))
		 temr02=temr02+abs(dbz_lin(i,j,k))
		 !print*,i,j,k,dbz_prt(i,j,k),dbz_org(i,j,k),dbz_lin(i,j,k)
		 !if(dbz_prt(i,j,k).eq.dbz_org(i,j,k)) print*,"dbz_prt(i,j,k)==dbz_org(i,j,k)"
	     temr03=temr03+1
	   endif
	enddo
  enddo
enddo
if(temr02>0.0) then 
  print*,temr01,temr02,temr03
  ratio2=temr01/temr02
else
  ratio2=1
endif
!ratio2=1.0+(sum(abs(dbz_prt(is:ie,js:je,ks:ke)-dbz_org(is:ie,js:je,ks:ke)))-sum(abs(dbz_lin(is:ie,js:je,ks:ke)))) &
!          /((ie-is+1)*(je-js+1)*(ke-ks+1))
if(print_lvl>=5) print('(A,3F12.8,4E12.5)'),"dbz h(x+dx)/h(x),ratio,ratio2,mag_std,sum org,sum prt,sum tl"      &
                                                 ,sum(abs(dbz_prt(is:ie,js:je,ks:ke)))/sum(abs(dbz_org(is:ie,js:je,ks:ke))) &
                                                 ,ratio,ratio2,mag_std  & !stdqr  &
                                                 ,sum(abs(dbz_org(is:ie,js:je,ks:ke))) &
                                                 ,sum(abs(dbz_prt(is:ie,js:je,ks:ke))) &
                                                 ,sum(abs(dbz_lin(is:ie,js:je,ks:ke)))
if(print_lvl>=10) print*,"------------------------------------------------"
!if(print_lvl>=10) print*,"zmm ratio"
!ratio=sum(abs(zmm_prt(is:ie,js:je,ks:ke)-zmm_lin(is:ie,js:je,ks:ke)))/sum(abs(zmm_org(is:ie,js:je,ks:ke)))
!ratio2=sum(abs(zmm_lin(is:ie,js:je,ks:ke)))/sum(abs(zmm_prt(is:ie,js:je,ks:ke)-zmm_org(is:ie,js:je,ks:ke)))
!if(print_lvl>=5) print('(A,3F12.8,4E12.5)'),"zmm h(x+dx)/h(x),ratio,ratio2,mag_std,sum org,sum prt,sum tl"  &                                                 
!                                                 ,sum(abs(zmm_prt(is:ie,js:je,ks:ke)))/sum(abs(zmm_org(is:ie,js:je,ks:ke))) &
!                                                 ,ratio,ratio2,mag_std  &!stdqr  &
!                                                 ,sum(abs(zmm_org(is:ie,js:je,ks:ke))) &
!                                                 ,sum(abs(zmm_prt(is:ie,js:je,ks:ke))) &
!                                                 ,sum(abs(zmm_lin(is:ie,js:je,ks:ke)))


tlopt=tlopt0
gropt=1  !gropt0
grd_chk_lt=0
grd_chk_rt=0
!do k=ks,ke
!  do j=js,je
!    do i=is,ie
!      call oudbzcalc_lin(qv(i,j,k),qr_org(i,j,k),qs_org(i,j,k),qg_org(i,j,k),nr(i,j,k),           &
!                         ns(i,j,k),ng(i,j,k),tc(i,j,k),p(i,j,k),dbz_lin(i,j,k),                   &
!                         1,1,1,0,0,0,rn0_r,rn0_s,rn0_g,                                           &
!                         rhos,rhog,dqr(i,j,k),dqs(i,j,k),dqg(i,j,k),                              &
!                         dnr(i,j,k),dns(i,j,k),dng(i,j,k),zmm_lin(i,j,k),                         &
!                         tlopt,gropt,i,j,k,zmm_lin(i,j,k),keepconstopt)
!      grd_chk_lt=grd_chk_lt+zmm_lin(i,j,k)*zmm_lin(i,j,k)
!      grd_chk_rt=grd_chk_rt+qr_prt(i,j,k)*dqr(i,j,k)+qs_prt(i,j,k)*dqs(i,j,k)+qg_prt(i,j,k)*dqg(i,j,k)
!    enddo
!  enddo
!enddo

!if(print_lvl>=5) print*,"zmm gradient check:",grd_chk_lt,grd_chk_rt

gropt=2
grd_chk_lt=0
grd_chk_rt=0
if(tlopt>=1.and.gropt==2) then
!  print*,"test dbz adjoint"
endif

do k=ks,ke
  do j=js,je
    do i=is,ie
      grd_chk_lt=grd_chk_lt+dbz_lin(i,j,k)*dbz_lin(i,j,k)
      call oudbzcalc_lin(qv_org(i,j,k),qr_org(i,j,k),qs_org(i,j,k),qg_org(i,j,k),nr(i,j,k),           &
                         ns(i,j,k),ng(i,j,k),tc_org(i,j,k),p(i,j,k),dbz_lin(i,j,k),                   &
                         1,1,1,0,0,0,rn0_r,rn0_s,rn0_g,                                               &
                         rhos,rhog,dtc(i,j,k),dqv(i,j,k),dqr(i,j,k),dqs(i,j,k),dqg(i,j,k),            &
                         dnr(i,j,k),dns(i,j,k),dng(i,j,k),zmm_org(i,j,k),                             &
                         tlopt,gropt,i,j,k,dbz_lin(i,j,k),keepconstopt)
      !grd_chk_lt=grd_chk_lt+dbz_lin(i,j,k)*dbz_lin(i,j,k)
      grd_chk_rt=grd_chk_rt+qr_prt(i,j,k)*dqr(i,j,k)+qs_prt(i,j,k)*dqs(i,j,k)+qg_prt(i,j,k)*dqg(i,j,k) &
	                       +tc_prt(i,j,k)*dtc(i,j,k)+qv_prt(i,j,k)*dqv(i,j,k)
    enddo
  enddo
enddo

if(print_lvl>=5) print*,"dbz gradient check:",grd_chk_lt,grd_chk_rt

mag_int=0.5
mag_std=mag_std*mag_int

icount=icount+1
!stop
enddo ! do while(mag_std<=max_mag)

close(1234)




open(1001,file=trim(diagfilename)//'.ctl')
write(1001,'(100a)')  'DSET    ./'//trim(diagfilename)//'.dat'
write(1001,'(100a)')  "TITLE   tangent linear check  "
write(1001,'(100a)')  "OPTIONS little_endian  "
write(1001,'(100a)')  "UNDEF   -999.0  "
write(1001,'(a10,i4,100a)')  "XDEF      ",ie-is+1,"  LINEAR    1 1  "
write(1001,'(a10,i4,100a)')  "YDEF      ",je-js+1,"  LINEAR    1 1  "
write(1001,'(a10,i4,100a)')  "ZDEF      ",ke-ks+1,"  LINEAR    1 1  "
write(1001,'(a10,i10,100a)') "TDEF      ",icount,"  LINEAR  07:00Z07jul2013        01MN  "
write(1001,'(100a)')  "VARS  6  "
write(1001,'(a10,i4,100a)')  "zo        ",ke-ks+1," 99          zmm org  "
write(1001,'(a10,i4,100a)')  "zp        ",ke-ks+1," 99          zmm prt  "
write(1001,'(a10,i4,100a)')  "zl        ",ke-ks+1," 99          zmm lin  "
write(1001,'(a10,i4,100a)')  "do        ",ke-ks+1," 99          dbz org  "
write(1001,'(a10,i4,100a)')  "dp        ",ke-ks+1," 99          dbz prt  "
write(1001,'(a10,i4,100a)')  "dl        ",ke-ks+1," 99          dbz lin  "
write(1001,'(100a)')  "ENDVARS  "
close(1001)


      
contains

subroutine readdata()

implicit none

character(len=256)  :: filename='./test_data.dat'
integer             :: nvar=14
integer             :: ivar

! 5, 6, 8, 9, 10, 11, 12, 13
! t, p, qv,qc,qr, qi, qs, qg

open(1001,file=trim(filename),form='binary')
if(print_init==1) print*,"filename:",trim(filename)
do ivar=1,nvar
  read(1001) temra01
  if(ivar==5) then
    tc=temra01
    if(print_init==1) print('(A,2E12.5)'),"tc max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==6) then
    p=temra01
    if(print_init==1) print('(A,2E12.5)'),"p  max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==8) then
    qv=temra01
    if(print_init==1) print('(A,2E12.5)'),"qv max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==9) then
    qc=temra01
    if(print_init==1) print('(A,2E12.5)'),"qc max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==10) then
    qr=temra01
    if(print_init==1) print('(A,2E12.5)'),"qr max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==11) then
    qi=temra01
    if(print_init==1) print('(A,2E12.5)'),"qi max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==12) then
    qs=temra01
    if(print_init==1) print('(A,2E12.5)'),"qs max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
  endif
  if(ivar==13) then
    qg=temra01
    if(print_init==1) print('(A,2E12.5)'),"qg max,min:",maxval(maxval(maxval(temra01(3:nx-2,3:ny-2,3:20),1),1),1), &
                         minval(minval(minval(temra01(3:nx-2,3:ny-2,3:20),1),1),1)
    exit
  endif
enddo

close(1001)
end subroutine readdata


FUNCTION GASDEV(IDUM)
!
!-----------------------------------------------------------------------
!
!  PURPOSE:
!
!  Generates a random number from normal distribution by feeding
!  a negative integer iseed.
!
!  Added by M.Tong
!  Reference: Numerical Recipes
!
!-----------------------------------------------------------------------
!
!  INPUT :
!
!    IDUM      an arbitrary negative integer as a seed for a
!              sequence of random numbers
!
!  OUTPUT:
!
!    GASDEV    A random number from Gaussian distribution with mean of 0
!              and standard deviation of 1.
!
!-----------------------------------------------------------------------
!
!
!-----------------------------------------------------------------------
!
!  Variable Declarations:
!
!-----------------------------------------------------------------------
!
  IMPLICIT NONE        ! Force explicit declarations

  INTEGER :: IDUM        ! The seed for random number generation
  REAL :: GASDEV         ! The function to generate random number.
!
!-----------------------------------------------------------------------
!
!  Miscellaneous local variables:
!
!-----------------------------------------------------------------------
!
   INTEGER,SAVE::ISET
   REAL,SAVE::GSET
   REAL :: V1, V2, R
   REAL :: RAN1
   REAL :: FAC
   DATA ISET/0/
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!
!  Beginning of executable code...
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!
  IF (ISET.EQ.0) THEN
  1 V1=2.*RAN1(IDUM)-1.
    V2=2.*RAN1(IDUM)-1.
    R=V1**2+V2**2
    IF(R.GE.1.)GO TO 1
    FAC=SQRT(-2.*LOG(R)/R)
    GSET=V1*FAC
    GASDEV=V2*FAC
    ISET=1
  ELSE
    GASDEV=GSET
    ISET=0
  ENDIF

  RETURN
END FUNCTION GASDEV

end program linear_check

!
!##################################################################
!##################################################################
!######                                                      ######
!######                  FUNCTION RAN1                       ######
!######                                                      ######
!######                     Developed by                     ######
!######     Center for Analysis and Prediction of Storms     ######
!######                University of Oklahoma                ######
!######                                                      ######
!##################################################################
!##################################################################
!

  FUNCTION RAN1(IDUM)
!
!-----------------------------------------------------------------------
!
!  PURPOSE:
!
!  Generates a random number between 0 and 1 by feeding
!  a negative integer iseed.
!
!  Added by M.Tong
!  Reference: "Seminumerical Algorithms" by Donald Knuth
!
!-----------------------------------------------------------------------
!
!  INPUT :
!
!    IDUM      an arbitrary negative integer as a seed for a
!              sequence of random numbers
!
!  OUTPUT:
!
!    RAN1      A random number between 0 and 1.
!
!-----------------------------------------------------------------------
!
!
!-----------------------------------------------------------------------
!
!  Variable Declarations:
!
!-----------------------------------------------------------------------
!
  IMPLICIT NONE        ! Force explicit declarations
  INTEGER :: IDUM        ! The seed for random number generation
  REAL :: RAN1           ! The function to generate random number.
!
!-----------------------------------------------------------------------
!
!  Miscellaneous local variables:
!
!-----------------------------------------------------------------------
!
  REAL,SAVE :: R(97)
  INTEGER :: IX1,IX2,IX3,J,IFF
  INTEGER :: M1,M2,M3,IA1,IA2,IA3,IC1,IC2,IC3
  REAL :: RM1,RM2
  SAVE IX1,IX2,IX3

  PARAMETER (M1=259200,IA1=7141,IC1=54773,RM1=3.8580247E-6)
  PARAMETER (M2=134456,IA2=8121,IC2=28411,RM2=7.4373773E-6)
  PARAMETER (M3=243000,IA3=4561,IC3=51349)
  DATA IFF /0/
!
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!
!  Beginning of executable code...
!
!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
!
!
!----------------------------------------------------------------------
!
!  Initialize the sequence of random numbers between 0 and 1,
!  using iseed.
!
!----------------------------------------------------------------------
!
  IF (IDUM.LT.0.OR.IFF.EQ.0) THEN
    IFF=1
    IX1=MOD(IC1-IDUM,M1)
    IX1=MOD(IA1*IX1+IC1,M1)
    IX2=MOD(IX1,M2)
    IX1=MOD(IA1*IX1+IC1,M1)
    IX3=MOD(IX1,M3)
    DO J=1,97
      IX1=MOD(IA1*IX1+IC1,M1)
      IX2=MOD(IA2*IX2+IC2,M2)
      R(J)=(FLOAT(IX1)+FLOAT(IX2)*RM2)*RM1
    ENDDO
    IDUM=1
  ENDIF
  IX1=MOD(IA1*IX1+IC1,M1)
  IX2=MOD(IA2*IX2+IC2,M2)
  IX3=MOD(IA3*IX3+IC3,M3)
  J=1+(97*IX3)/M3
  IF(J.GT.97.OR.J.LT.1)THEN
    WRITE(*,*)'J is greater than 97 or less than 1','IDUM=',IDUM
    STOP
  ENDIF
  RAN1=R(J)
  R(J)=(FLOAT(IX1)+FLOAT(IX2)*RM2)*RM1

  RETURN
  END FUNCTION RAN1
