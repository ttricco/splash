module particleplots
 implicit none

contains
!
!  Drives raw particle plots
!  Handles different particle types, particle cross-sections, particle labelling
!
!  Arguments:
!
!
subroutine particleplot(xplot,yplot,zplot,h,ntot,iplotx,iploty, &
                        icolourpart,npartoftype, &
                        use_zrange,zmin,zmax,labelz)
  use labels
  use settings_data, only:ndim,icoords,ntypes
  use settings_part
  implicit none
  integer, intent(in) :: ntot, iplotx, iploty
  integer, intent(in), dimension(ntot) :: icolourpart
  integer, dimension(maxparttypes), intent(in) :: npartoftype
  real, dimension(ntot), intent(in) :: xplot, yplot, zplot, h
  real, dimension(ntot) :: xerrb, yerrb, herr
  real, intent(in) :: zmin,zmax
  logical, intent(in) :: use_zrange
  character(len=*), intent(in) :: labelz
  integer :: j,n,itype,linewidth,icolourindex,nplotted
  integer :: lenstring,index1,index2,ntotplot,icolourstart
  real :: charheight
  character(len=20) :: string
  
  !--query current character height and colour
  call pgqch(charheight)
  call pgqci(icolourstart)
  !!print "(a,i8)",' entering particle plot, total particles = ',ntot
  !
  !--check for errors in input
  !
  ntotplot = sum(npartoftype(1:ntypes))
  if (ntot.lt.ntotplot) then
     print "(a)",' ERROR: number of particles input < number of each type '
     print*,ntot,npartoftype(1:ntypes)
     return
  elseif (ntot.ne.ntotplot) then
     print "(a)",' WARNING: particleplot: total not equal to sum of types on input'
     print*,' ntotal = ',ntot,' sum of types = ',ntotplot
  endif
  !
  !--loop over all particle types
  !
  index1 = 1
  over_types: do itype=1,ntypes
     index2 = index1 + npartoftype(itype) - 1
     if (index2.gt.ntot) then 
        index2 = ntot
        print "(a)",' WARNING: incomplete data'
     endif
     if (index2.lt.index1) exit over_types

     if (iplotpartoftype(itype) .and. npartoftype(itype).gt.0) then
        if (use_zrange) then
           !
           !--if particle cross section, plot particles only in a defined (z) coordinate range
           !
           nplotted = 0
           do j=index1,index2
              if (zplot(j).lt.zmax .and. zplot(j).gt.zmin) then
                 if (icolourpart(j).gt.0) then
                    nplotted = nplotted + 1
                    call pgsci(icolourpart(j))
                    call pgpt(1,xplot(j),yplot(j),imarktype(itype))
                 endif
                 !--plot circle of interaction if gas particle
                 if (itype.eq.1 .and. ncircpart.gt.0 .and. ANY(icircpart(1:ncircpart).eq.j)) then
                    call pgcirc(xplot(j),yplot(j),2*h(j))
                 endif
                 !!--plot particle label
                 if (ilabelpart) then
                    call pgnumb(j,0,1,string,lenstring)
                    call danpgsch(4.0,2)
                    call pgtext(xplot(j),yplot(j),string(1:lenstring))
                    call pgsch(charheight)
                 endif
              endif
           enddo
           print*,' plotted ',nplotted,' of ', &
             index2-index1+1,trim(labeltype(itype))//' particles in range ', &
             trim(labelz),' = ',zmin,' -> ',zmax
        else
           !
           !--otherwise plot all particles of this type using appropriate marker and colour
           !
           call pgqci(icolourindex)
           if (all(icolourpart(index1:index2).eq.icolourpart(index1))) then
              print "(a,i8,1x,a)",' plotting ',index2-index1+1,trim(labeltype(itype))//' particles'
              call pgsci(icolourpart(index1))
              call pgpt(npartoftype(itype),xplot(index1:index2),yplot(index1:index2),imarktype(itype))
           else
              nplotted = 0
              do j=index1,index2
                 if (icolourpart(j).gt.0) then
                    nplotted = nplotted + 1
                    call pgsci(icolourpart(j))
                    call pgpt(1,xplot(j),yplot(j),imarktype(itype))
                 endif
              enddo
              print*,' plotted ',nplotted,' of ',index2-index1+1,trim(labeltype(itype))//' particles'
           endif
           call pgsci(icolourindex)

           if (ilabelpart) then
              !!--plot particle labels
              print*,'plotting particle labels ',index1,':',index2
              do j=index1,index2
                 call pgnumb(j,0,1,string,lenstring)
                 call danpgsch(4.0,2)
                 call pgtext(xplot(j),yplot(j),string(1:lenstring))
                 call pgsch(charheight)
              enddo
           endif
        endif
     endif
     index1 = index2 + 1
  enddo over_types

  !
  !--plot circles of interaction (ie a circle of radius 2h)
  !  around all or selected particles. For plots with only one coordinate axis, 
  !  these are plotted as error bars in the coordinate direction.
  !
  if (ncircpart.gt.0) then
     !
     !--set fill area style and line width
     !
     call pgsfs(2)
     call pgqlw(linewidth)
     call pgslw(2)
     call pgqci(icolourindex)
     call pgsci(2)
     
     if (iplotx.le.ndim .and. iploty.le.ndim) then
        print*,'plotting circles of interaction',ncircpart
        do n = 1,ncircpart
           if (icircpart(n).gt.ntot) then 
              print*,'error: particle index > number of particles'
           else
              if (icoordsnew.ne.icoords) then   
                 call plot_kernel_gr(icoords,xplot(icircpart(n)),  &
                      yplot(icircpart(n)),2*h(icircpart(n)))
              else
                 call pgcirc(xplot(icircpart(n)),  &
                      yplot(icircpart(n)),2*h(icircpart(n)))
              endif
           endif        
        enddo

     else
        !!--only on specified particles
        do n=1,ncircpart
           if (icircpart(n).gt.ntot) then
              print*,'error: particle index > number of particles'
              xerrb(n) = 0.
              yerrb(n) = 0.
              herr(n) = 0.
           else
              xerrb(n) = xplot(icircpart(n))
              yerrb(n) = yplot(icircpart(n))
              herr(n) = 2.*h(icircpart(n))
           endif
        enddo         
        if (iplotx.le.ndim) then
           print*,'plotting ',ncircpart,' error bars x axis '
           call pgerrb(5,ncircpart,xerrb(1:ncircpart), &
                yerrb(1:ncircpart),herr(1:ncircpart),1.0)
        elseif (iploty.le.ndim) then
           print*,'plotting ',ncircpart,' error bars y axis'
           call pgerrb(6,ncircpart,xerrb(1:ncircpart), &
                yplot(1:ncircpart),herr(1:ncircpart),1.0)      
        endif
     endif
     
     call pgslw(linewidth)
     call pgsci(icolourindex)
     
  endif

!
!--reset colour
!
  call pgsci(icolourstart)

  return
     
end subroutine particleplot

end module particleplots
