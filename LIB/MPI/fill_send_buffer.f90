!> \file
!> \callgraph
! ********************************************************************************************
! WABBIT
! ============================================================================================
!> \name fill_send_buffer.f90
!> \version 0.5
!> \author msr
!
!> \brief fill send buffer
!
!>
!! input:    
!!           - params, heavy data
!!           - com matrix line
!!           - proc rank
!!
!! output:   
!!           - filled send buffer
!!           - second com matrix line with receiver data position (column number) in send buffer
!!
!! \n
! --------------------------------------------------------------------------------------------
!> neighbor codes: \n
! ---------------
!> for imagination:  
!!                   - 6-sided dice with '1'-side on top, '6'-side on bottom, '2'-side in front
!!                   - edge: boundary between two sides - use sides numbers for coding
!!                   - corner: between three sides - so use all three sides numbers
!!                   - block on higher/lower level: block shares face/edge and one unique corner,
!!                     so use this corner code in second part of neighbor code
!!
!! faces:  '__1/___', '__2/___', '__3/___', '__4/___', '__5/___', '__6/___' \n
!! edges:  '_12/___', '_13/___', '_14/___', '_15/___'
!!         '_62/___', '_63/___', '_64/___', '_65/___'
!!         '_23/___', '_25/___', '_43/___', '_45/___' \n
!! corner: '123/___', '134/___', '145/___', '152/___'
!!         '623/___', '634/___', '645/___', '652/___' \n
!!
!! complete neighbor code array, 74 possible neighbor relations \n
!! neighbors = (/'__1/___', '__2/___', '__3/___', '__4/___', '__5/___', '__6/___', '_12/___', '_13/___', '_14/___', '_15/___',
!!               '_62/___', '_63/___', '_64/___', '_65/___', '_23/___', '_25/___', '_43/___', '_45/___', '123/___', '134/___',
!!               '145/___', '152/___', '623/___', '634/___', '645/___', '652/___', '__1/123', '__1/134', '__1/145', '__1/152',
!!               '__2/123', '__2/623', '__2/152', '__2/652', '__3/123', '__3/623', '__3/134', '__3/634', '__4/134', '__4/634',
!!               '__4/145', '__4/645', '__5/145', '__5/645', '__5/152', '__5/652', '__6/623', '__6/634', '__6/645', '__6/652',
!!               '_12/123', '_12/152', '_13/123', '_13/134', '_14/134', '_14/145', '_15/145', '_15/152', '_62/623', '_62/652',
!!               '_63/623', '_63/634', '_64/634', '_64/645', '_65/645', '_65/652', '_23/123', '_23/623', '_25/152', '_25/652',
!!               '_43/134', '_43/634', '_45/145', '_45/645' /) \n
! --------------------------------------------------------------------------------------------
!>
!! = log ======================================================================================
!! \n
!! 13/01/17 - create for v0.4 \n
!! 01/02/17 - switch to 3D, v0.5
!
! ********************************************************************************************

subroutine fill_send_buffer( params, hvy_block, com_lists, com_matrix_line, rank, int_send_buffer, real_send_buffer, synch_stage )

!---------------------------------------------------------------------------------------------
! modules

!---------------------------------------------------------------------------------------------
! variables

    implicit none

    !> user defined parameter structure
    type (type_params), intent(in)                  :: params

    !> heavy data array - block data
    real(kind=rk), intent(in)                       :: hvy_block(:, :, :, :, :)

    !> communication lists:
    integer(kind=ik), intent(in)                    :: com_lists(:, :, :)

    !> com matrix line
    integer(kind=ik), intent(in)                    :: com_matrix_line(:)

    !> proc rank
    integer(kind=ik), intent(in)                    :: rank

    !> integer send buffer
    integer(kind=ik), intent(inout)                 :: int_send_buffer(:,:)
    !> real send buffer
    real(kind=rk), intent(inout)                    :: real_send_buffer(:,:)

    !> synch stage
    integer(kind=ik), intent(in)                    :: synch_stage

    ! loop variable
    integer(kind=ik)                                :: k, i

    ! column number of send buffer, position in integer buffer
    integer(kind=ik)                                :: column_pos, int_pos

    ! index of send buffer, return from create_send_buffer subroutine
    integer(kind=ik)                                :: buffer_i


!---------------------------------------------------------------------------------------------
! interfaces

!---------------------------------------------------------------------------------------------
! variables initialization

    ! reset column number
    column_pos = 1

!---------------------------------------------------------------------------------------------
! main body

    ! loop over all line elements
    do k = 1, size(com_matrix_line,1)

        ! communication to other proc, do not work with internal communications
        if ( (com_matrix_line(k) /= 0) .and. (k /= rank+1) ) then

            ! first: real data
            ! ----------------

            ! write real send buffer for proc k
            if ( params%threeD_case ) then
                ! 3D:
                call create_send_buffer_3D(params, hvy_block, com_lists( 1:com_matrix_line(k), :, k), com_matrix_line(k), real_send_buffer( :, column_pos ), buffer_i)
            else
                ! 2D:
                if ( synch_stage /= 4 ) then
                    call create_send_buffer_2D(params, hvy_block(:, :, 1, :, :), com_lists( 1:com_matrix_line(k), :, k), com_matrix_line(k), real_send_buffer( :, column_pos ), buffer_i)
                else
                    call create_redundant_send_buffer_2D(params, hvy_block(:, :, 1, :, :), com_lists( 1:com_matrix_line(k), :, k), com_matrix_line(k), real_send_buffer( :, column_pos ), buffer_i)
                end if
            end if


            ! second: integer data
            ! --------------------

            ! save real buffer length
            int_send_buffer(1, column_pos) = buffer_i

            ! reset position
            int_pos = 2

            ! loop over all communications to this proc
            do i = 1, com_matrix_line(k)

                ! int buffer entry: neighbor block id, neighborhood, level difference
                int_send_buffer( int_pos  , column_pos ) = com_lists( i, 4, k)
                int_send_buffer( int_pos+1, column_pos ) = com_lists( i, 5, k)
                int_send_buffer( int_pos+2, column_pos ) = com_lists( i, 6, k)
                ! increase int buffer position
                int_pos = int_pos + 3

            end do

            ! mark end of int send buffer, to avoid reseting
            int_send_buffer(int_pos, column_pos) = -99

            ! third: increase column number
            ! ------------------------------------
            column_pos = column_pos + 1

        end if

    end do

end subroutine fill_send_buffer
