!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name copy_ghost_nodes_2D.f90
!> \version 0.4
!> \author msr
!
!> \brief copy ghost points from sender block to receiver block 
!> \note works only for block on same process
!
!> \details
!! input:    
!!           - heavy data array
!!           - sender block id
!!           - receiver block id
!!           - neighbor relations between sender/receiver
!!           - level difference between these two blocks
!!
!! output:   
!!           - heavy data array
!!
!! \n
! -------------------------------------------------------------------------------------------------------------------------
!> dirs = (/'__N', '__E', '__S', '__W', '_NE', '_NW', '_SE', '_SW', 'NNE', 'NNW', 'SSE', 'SSW', 'ENE', 'ESE', 'WNW', 'WSW'/) \n
! -------------------------------------------------------------------------------------------------------------------------
!>
!!
!! = log ======================================================================================
!! \n
!! 09/11/16 - create for v0.4 \n
!! 31/03/17 - add non-uniform mesh correction \n
!! 12/04/17 - remove redundant nodes between blocks with meshlevel +1
! ********************************************************************************************

subroutine copy_ghost_nodes_2D( params, hvy_block, sender_id, receiver_id, neighborhood, level_diff)

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> user defined parameter structure
    type (type_params), intent(in)                  :: params
    !> heavy data array - block data
    real(kind=rk), intent(inout)                    :: hvy_block(:, :, :, :)
    !> heavy data id's
    integer(kind=ik), intent(in)                    :: sender_id, receiver_id
    !> neighborhood relation, id from dirs
    integer(kind=ik), intent(in)                    :: neighborhood
    !> difference between block levels
    integer(kind=ik), intent(in)                    :: level_diff

    ! grid parameter
    integer(kind=ik)                                :: Bs, g
    ! loop variables
    integer(kind=ik)                                :: dF

    ! interpolation variables
    real(kind=rk), dimension(:,:), allocatable      :: data_corner, data_corner_fine, data_edge, data_edge_fine


    ! variable for non-uniform mesh correction: remove redundant node between fine->coarse blocks
    integer(kind=ik)                                :: rmv_redundant
!---------------------------------------------------------------------------------------------
! interfaces

    ! grid parameter
    Bs    = params%number_block_nodes
    g     = params%number_ghost_nodes

    rmv_redundant = 0

    ! set non-uniform mesh correction
    if ( params%non_uniform_mesh_correction ) then
        rmv_redundant = 1
    else
        rmv_redundant = 0
    end if

!---------------------------------------------------------------------------------------------
! variables initialization

    allocate( data_corner( g, g)  )
    allocate( data_corner_fine( 2*g-1, 2*g-1)  )
    !allocate( data_edge( (Bs+1)/2 + g/2, (Bs+1)/2 + g/2)  )
    allocate( data_edge( (Bs+1)/2 + g, (Bs+1)/2 + g)  )
    !allocate( data_edge_fine( Bs+g, Bs+g)  )
    allocate( data_edge_fine( Bs+2*g, Bs+2*g)  )

!---------------------------------------------------------------------------------------------
! main body

    select case(neighborhood)
        ! '__N'
        case(1)
            if ( level_diff == 0 ) then
                ! sender/receiver on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    hvy_block( Bs+g+1:Bs+g+g, g+1:Bs+g, dF, receiver_id ) = hvy_block( g+2:g+1+g, g+1:Bs+g, dF, sender_id )
                end do

            else
                ! error case (there should be no level difference between sender/receiver)
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '__E'
        case(2)
            if ( level_diff == 0 ) then
                ! sender/receiver on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    hvy_block( g+1:Bs+g, 1:g, dF, receiver_id ) = hvy_block( g+1:Bs+g, Bs:Bs-1+g, dF, sender_id )
                end do

            else
                ! error case (there should be no level difference between sender/receiver)
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '__S'
        case(3)
            if ( level_diff == 0 ) then
                ! sender/receiver on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    hvy_block( 1:g, g+1:Bs+g, dF, receiver_id ) = hvy_block( Bs:Bs-1+g, g+1:Bs+g, dF, sender_id )
                end do

            else
                ! error case (there should be no level difference between sender/receiver)
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '__W'
        case(4)
            if ( level_diff == 0 ) then
                ! sender/receiver on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    hvy_block( g+1:Bs+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( g+1:Bs+g, g+2:g+1+g, dF, sender_id )
                end do

            else
                ! error case (there should be no level difference between sender/receiver)
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '_NE'
        case(5)
            if ( level_diff == 0 ) then
                ! blocks on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( g+2-rmv_redundant:g+1+g, Bs:Bs-1+g+rmv_redundant, dF, sender_id )
                    hvy_block( Bs+g+1:Bs+g+g, 1:g, dF, receiver_id ) = hvy_block( g+2:g+1+g, Bs:Bs-1+g, dF, sender_id )
                end do

            elseif ( level_diff == -1 ) then
                ! sender one level down
                ! interpolate data
                do dF = 1, params%number_data_fields
                    ! data to refine
                    data_corner = hvy_block( g+1:g+g, Bs+1:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_corner , data_corner_fine, params%order_predictor)
                    ! data to synchronize
                    data_corner = data_corner_fine(2:g+1, g-1:2*g-2)
                    ! write data
                    hvy_block( Bs+g+1:Bs+g+g, 1:g, dF, receiver_id ) = data_corner
                end do

            elseif ( level_diff == 1) then
                ! sender one level up
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1:Bs+g+g, 1:g, dF, receiver_id ) = hvy_block( g+3:g+1+g+g:2, Bs-g:Bs-2+g:2, dF, sender_id )
                    hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( g+3-rmv_redundant*2:g+1+g+g:2, Bs-g:Bs-2+rmv_redundant*2+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '_NW'
        case(6)
            if ( level_diff == 0 ) then
                ! blocks on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( g+2-rmv_redundant:g+1+g, g+2-rmv_redundant:g+1+g, dF, sender_id )
                    hvy_block( Bs+g+1:Bs+g+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( g+2:g+1+g, g+2:g+1+g, dF, sender_id )
                end do

            elseif ( level_diff == -1 ) then
                ! sender one level down
                ! interpolate data
                do dF = 1, params%number_data_fields
                    ! data to refine
                    data_corner = hvy_block( g+1:g+g, g+1:g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_corner , data_corner_fine, params%order_predictor)
                    ! data to synchronize
                    data_corner = data_corner_fine(2:g+1, 2:g+1)
                    ! write data
                    hvy_block( Bs+g+1:Bs+g+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = data_corner
                end do

            elseif ( level_diff == 1) then
                ! sender one level up
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1:Bs+g+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( g+3:g+1+g+g:2, g+3:g+1+g+g:2, dF, sender_id )
                    hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( g+3-rmv_redundant*2:g+1+g+g:2, g+3-rmv_redundant*2:g+1+g+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '_SE'
        case(7)
            if ( level_diff == 0 ) then
                ! blocks on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g+rmv_redundant, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( Bs:Bs-1+g+rmv_redundant, Bs:Bs-1+g+rmv_redundant, dF, sender_id )
                    hvy_block( 1:g, 1:g, dF, receiver_id ) = hvy_block( Bs:Bs-1+g, Bs:Bs-1+g, dF, sender_id )
                end do

            elseif ( level_diff == -1 ) then
                ! sender one level down
                ! interpolate data
                do dF = 1, params%number_data_fields
                    ! data to refine
                    data_corner = hvy_block( Bs+1:Bs+g, Bs+1:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_corner , data_corner_fine, params%order_predictor)
                    ! data to synchronize
                    data_corner = data_corner_fine(g-1:2*g-2, g-1:2*g-2)
                    ! write data
                    hvy_block( 1:g, 1:g, dF, receiver_id ) = data_corner
                end do

            elseif ( level_diff == 1) then
                ! sender one level up
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g, 1:g, dF, receiver_id ) = hvy_block( Bs-g:Bs-2+g:2, Bs-g:Bs-2+g:2, dF, sender_id )
                    hvy_block( 1:g+rmv_redundant, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( Bs-g:Bs-2+rmv_redundant*2+g:2, Bs-g:Bs-2+rmv_redundant*2+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! '_SW'
        case(8)
            if ( level_diff == 0 ) then
                ! blocks on same level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g+rmv_redundant, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( Bs:Bs-1+g+rmv_redundant, g+2-rmv_redundant:g+1+g, dF, sender_id )
                    hvy_block( 1:g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( Bs:Bs-1+g, g+2:g+1+g, dF, sender_id )
                end do

            elseif ( level_diff == -1 ) then
                ! sender one level down
                ! interpolate data
                do dF = 1, params%number_data_fields
                    ! data to refine
                    data_corner = hvy_block( Bs+1:Bs+g, g+1:g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_corner , data_corner_fine, params%order_predictor)
                    ! data to synchronize
                    data_corner = data_corner_fine(g-1:2*g-2, 2:g+1)
                    ! write data
                    hvy_block( 1:g, Bs+g+1:Bs+g+g, dF, receiver_id ) = data_corner
                end do

            elseif ( level_diff == 1) then
                ! sender one level up
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( Bs-g:Bs-2+g:2, g+3:g+1+g+g:2, dF, sender_id )
                    hvy_block( 1:g+rmv_redundant, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( Bs-g:Bs-2+rmv_redundant*2+g:2, g+3-rmv_redundant*2:g+1+g+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'NNE'
        case(9)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( g+1:(Bs+1)/2+g/2+g, (Bs+1)/2+g/2:Bs+g, dF, sender_id )
                    data_edge = hvy_block( g+1:(Bs+1)/2+g+g, (Bs+1)/2:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( Bs+g+1:Bs+g+g, 1:Bs+g, dF, receiver_id ) = data_edge_fine(2:g+1, 1:Bs+g)
                    hvy_block( Bs+g+1:Bs+g+g, 1:Bs+g, dF, receiver_id ) = data_edge_fine(2:g+1, g+1:Bs+2*g)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1:Bs+g+g, g+(Bs+1)/2:Bs+g, dF, receiver_id ) = hvy_block( g+3:3*g+1:2, g+1:Bs+g:2, dF, sender_id )
                    hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, g+(Bs+1)/2:Bs+g, dF, receiver_id ) = hvy_block( g+3-rmv_redundant*2:3*g+1:2, g+1:Bs+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'NNW'
        case(10)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( g+1:(Bs+1)/2+g/2+g, g+1:(Bs+1)/2+g/2+g, dF, sender_id )
                    data_edge = hvy_block( g+1:(Bs+1)/2+g+g, g+1:(Bs+1)/2+g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    hvy_block( Bs+g+1:Bs+g+g, g+1:Bs+2*g, dF, receiver_id ) = data_edge_fine(2:g+1, 1:Bs+g)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( Bs+g+1:Bs+g+g, g+1:g+(Bs+1)/2, dF, receiver_id ) = hvy_block( g+3:3*g+1:2, g+1:Bs+g:2, dF, sender_id )
                    hvy_block( Bs+g+1-rmv_redundant:Bs+g+g, g+1:g+(Bs+1)/2, dF, receiver_id ) = hvy_block( g+3-rmv_redundant*2:3*g+1:2, g+1:Bs+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'SSE'
        case(11)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( (Bs+1)/2+g/2:Bs+g, (Bs+1)/2+g/2:Bs+g, dF, sender_id )
                    data_edge = hvy_block( (Bs+1)/2:Bs+g, (Bs+1)/2:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( 1:g, 1:Bs+g, dF, receiver_id ) = data_edge_fine(Bs:Bs+g-1, 1:Bs+g)
                    hvy_block( 1:g, 1:Bs+g, dF, receiver_id ) = data_edge_fine(Bs+g:Bs+2*g-1, g+1:Bs+2*g)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g, g+(Bs+1)/2:Bs+g, dF, receiver_id ) = hvy_block( Bs-g:Bs+g-2:2, g+1:Bs+g:2, dF, sender_id )
                    hvy_block( 1:g+rmv_redundant, g+(Bs+1)/2:Bs+g, dF, receiver_id ) = hvy_block( Bs-g:Bs+g-2+rmv_redundant*2:2, g+1:Bs+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'SSW'
        case(12)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( (Bs+1)/2+g/2:Bs+g, g+1:(Bs+1)/2+g/2+g, dF, sender_id )
                    data_edge = hvy_block( (Bs+1)/2:Bs+g, g+1:(Bs+1)/2+g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( 1:g, g+1:Bs+2*g, dF, receiver_id ) = data_edge_fine(Bs:Bs+g-1, 1:Bs+g)
                    hvy_block( 1:g, g+1:Bs+2*g, dF, receiver_id ) = data_edge_fine(Bs+g:Bs+2*g-1, 1:Bs+g)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( 1:g, g+1:g+(Bs+1)/2, dF, receiver_id ) = hvy_block( Bs-g:Bs+g-2:2, g+1:Bs+g:2, dF, sender_id )
                    hvy_block( 1:g+rmv_redundant, g+1:g+(Bs+1)/2, dF, receiver_id ) = hvy_block( Bs-g:Bs+g-2+rmv_redundant*2:2, g+1:Bs+g:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'ENE'
        case(13)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( g+1:(Bs+1)/2+g/2+g, (Bs+1)/2+g/2:Bs+g, dF, sender_id )
                    data_edge = hvy_block( g+1:(Bs+1)/2+g+g, (Bs+1)/2:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( g+1:Bs+2*g, 1:g, dF, receiver_id ) = data_edge_fine(1:Bs+g, Bs:Bs+g-1)
                    hvy_block( g+1:Bs+2*g, 1:g, dF, receiver_id ) = data_edge_fine(1:Bs+g, Bs+g:Bs+2*g-1)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( g+1:g+(Bs+1)/2, 1:g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, Bs-g:Bs+g-2:2, dF, sender_id )
                    hvy_block( g+1:g+(Bs+1)/2, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, Bs-g:Bs+g-2+rmv_redundant*2:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'ESE'
        case(14)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( (Bs+1)/2+g/2:Bs+g, (Bs+1)/2+g/2:Bs+g, dF, sender_id )
                    data_edge = hvy_block( (Bs+1)/2:Bs+g, (Bs+1)/2:Bs+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( 1:Bs+g, 1:g, dF, receiver_id ) = data_edge_fine(1:Bs+g, Bs:Bs+g-1)
                    hvy_block( 1:Bs+g, 1:g, dF, receiver_id ) = data_edge_fine(g+1:Bs+2*g, Bs+g:Bs+2*g-1)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( g+(Bs+1)/2:Bs+g, 1:g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, Bs-g:Bs+g-2:2, dF, sender_id )
                    hvy_block( g+(Bs+1)/2:Bs+g, 1:g+rmv_redundant, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, Bs-g:Bs+g-2+rmv_redundant*2:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'WNW'
        case(15)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( g+1:(Bs+1)/2+g/2+g, g+1:(Bs+1)/2+g/2+g, dF, sender_id )
                    data_edge = hvy_block( g+1:(Bs+1)/2+g+g, g+1:(Bs+1)/2+g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    hvy_block( g+1:Bs+2*g, Bs+g+1:Bs+g+g, dF, receiver_id ) = data_edge_fine(1:Bs+g, 2:g+1)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( g+1:g+(Bs+1)/2, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, g+3:3*g+1:2, dF, sender_id )
                    hvy_block( g+1:g+(Bs+1)/2, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, g+3-rmv_redundant*2:3*g+1:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

        ! 'WSW'
        case(16)
            if ( level_diff == -1 ) then
                ! sender on lower level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    ! data to interpolate
                    !data_edge = hvy_block( (Bs+1)/2+g/2:Bs+g, g+1:(Bs+1)/2+g/2+g, dF, sender_id )
                    data_edge = hvy_block( (Bs+1)/2:Bs+g, g+1:(Bs+1)/2+g+g, dF, sender_id )
                    ! interpolate data
                    call prediction_2D( data_edge , data_edge_fine, params%order_predictor)
                    ! copy data
                    !hvy_block( 1:Bs+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = data_edge_fine(1:Bs+g, 2:g+1)
                    hvy_block( 1:Bs+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = data_edge_fine(g+1:Bs+2*g, 2:g+1)
                end do

            elseif ( level_diff == 1 ) then
                ! sender on higher level
                ! loop over all datafields
                do dF = 1, params%number_data_fields
                    !hvy_block( g+(Bs+1)/2:Bs+g, Bs+g+1:Bs+g+g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, g+3:3*g+1:2, dF, sender_id )
                    hvy_block( g+(Bs+1)/2:Bs+g, Bs+g+1-rmv_redundant:Bs+g+g, dF, receiver_id ) = hvy_block( g+1:Bs+g:2, g+3-rmv_redundant*2:3*g+1:2, dF, sender_id )
                end do

            else
                ! error case
                write(*,'(80("_"))')
                write(*,*) "ERROR: can not synchronize ghost nodes, mesh is not graded"
                stop
            end if

    end select

    ! clean up
    deallocate( data_corner  )
    deallocate( data_corner_fine  )
    deallocate( data_edge  )
    deallocate( data_edge_fine  )

end subroutine copy_ghost_nodes_2D
