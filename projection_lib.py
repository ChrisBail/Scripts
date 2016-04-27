# -*- coding: utf-8 -*-


from __future__ import division
import numpy as np

def change_basis(vector,teta_Z):
    """
    @author: baillard
    For the moment it's just implemented to work with rotation along Z axis
    The convention is a direct base with Z upward, angles are taken positive counter clockwise (trigo sense)
    """
    #vec=np.array([1./2,1./2,0])
    
    #teta_Z=45+180
    #teta_Y=0
    #teta_X=0
    
    rad=np.pi/180
    
    ### Transform into radians
    
    teta_Z=teta_Z*rad
    #teta_X=teta_X*rad
    #teta_Y=teta_Y*rad
    
    ### Get the rotation matrix along Z axis
    Rz=np.array([[np.cos(teta_Z),-np.sin(teta_Z),0],
                [np.sin(teta_Z),np.cos(teta_Z),0],
                  [0,0,1]])
                  
    #### X'=P^(-1)X
                  
    # Invert matrix
    Pz=np.linalg.inv(Rz)
    
    new_vec=np.dot(Pz,vector)
    
    return new_vec

def cartesian2spherical(vector):
    """Convert the Cartesian vector [x, y, z] to spherical coordinates [r, theta, phi].
    The parameter r is the radial distance, theta is the polar angle, and phi is the azimuth.
    @param vector:  The Cartesian vector [x, y, z].
    @type vector:   numpy rank-1, 3D array
    @return:        The spherical coordinate vector [r, theta, phi], angles are in radian
    @rtype:         numpy rank-1, 3D array
    """

    # The radial distance.
    r = np.linalg.norm(vector)

    # Unit vector.
    unit = vector / r

    # The polar angle.
    theta = np.arccos(unit[2])

    # The azimuth.
    phi = np.arctan2(unit[1], unit[0])

    # Return the spherical coordinate vector.
    return np.array([r, theta, phi])
    
def cartesian2geographical(vector):
    """Same as cartesian2spherical but azimuth is given depending on North (y) and clokwise and dip is given from horizontal (positive downward)
    """
    spher=cartesian2spherical(vector)
    
    r=spher[0]
    dip=-(np.pi/2 - spher[1])
    azi=np.pi/2 - spher[2]
    
    return np.array([r,dip,azi])
    
def spherical2cartesian(spherical_vect):
    """Convert the spherical coordinate vector [r, theta, phi] to the Cartesian vector [x, y, z].

    The parameter r is the radial distance, theta is the polar angle, and phi is the azimuth.


    @param spherical_vect:  The spherical coordinate vector [r, theta, phi].
    @type spherical_vect:   3D array or list
    @param cart_vect:       The Cartesian vector [x, y, z].
    @type cart_vect:        3D array or list
    """
    cart_vect=np.zeros(3)
    # Trig alias.
    sin_theta = np.sin(spherical_vect[1])

    # The vector.
    cart_vect[0] = spherical_vect[0] * np.cos(spherical_vect[2]) * sin_theta
    cart_vect[1] = spherical_vect[0] * np.sin(spherical_vect[2]) * sin_theta
    cart_vect[2] = spherical_vect[0] * np.cos(spherical_vect[1])
    
    return np.round(cart_vect,4)
    
def geographical2cartesian(geo_vect):
    """Convert the geographical coordinate vector [r, dip, azi] to the Cartesian vector [x, y, z].

    """
    spherical_vect=np.zeros(3)
    
    spherical_vect[0]=geo_vect[0]
    spherical_vect[1]=np.pi/2+geo_vect[1]
    spherical_vect[2]=np.pi/2-geo_vect[2]
    
    return spherical2cartesian(spherical_vect)
    
def focaxis2cartesian(filein,fileout,tetaz=0.0):
    """ 
    It takes a file which column are norm, axis Plunge and axis Azimuth and return coordinates in cartesian in the classical
    basis or a basis rotated along z axis with a value tetaz
    """
    #filein='/Users/baillard/_Moi/Programmation/Scripts/scratch2.txt'
    #fileout='scratch3.txt'
    
    ### Open files
    fic=open(filein,'r')
    foc=open(fileout,'w')
    rad=np.pi/180
    #tetaz=0.0
    #rad=np.pi/180
    #tetaz=tetaz*rad
    
    lines=fic.readlines()
    fic.close()
    ### Check if file contains 3 Fields
    num_field=len(lines[0].split())
    if num_field != 3:
        raise Exception("Number of fields in %s is not equal to 3" %(filein))
    
    for line in lines:
        ### Convert to cartesian coordinates
        geo_vect=np.array([float(x) for x in line.split()])
        ### Convert to radians
        geo_vect[1]=geo_vect[1]*rad
        geo_vect[2]=geo_vect[2]*rad
        cart_vect=geographical2cartesian(geo_vect)
        ### Change basis
        new_cart_vect=change_basis(cart_vect,tetaz)
        ### Print in file
        foc.write("%7.3f %7.3f %7.3f\n" %(new_cart_vect[0],new_cart_vect[1],new_cart_vect[2]))
        
    foc.close()