% test the cmmfile c++ mathematica matlab data file interface
function in = test_cmm()
   %create some data
   out = {int32([1 2 3 4]) 'hello' [10.1 100.5; 6.6 5.4; 2.2 2.1] {'hello' 'world'; 'doll' 'iset'}}
   
   cmm_write_file('test_mat.dat', out)
   

   in = cmm_read_file('test_mat.dat')
   
   
   %return 
   % now check the binary files from cmm code
   
   incmm = cmm_read_file('test_cpp.dat')
   
   incmm = cmm_read_file('test2_cpp.dat')
   
   incmm = cmm_read_file('test3_cpp.dat')
   
   % now check the binary files form mathematica
   
   inmath = cmm_read_file('test_math.dat')
   
   % check higher dimensions
   dat = cmm_reshape(int32([1:2*3*4*5]), [3 2 4 5]);
   
   cmm_write_file('test2_mat.dat', {dat});
   
   in = cmm_read_file('test2_mat.dat');
   
   inmath = cmm_read_file('test2_math.dat')
   
  
   % test skipping
   in = cmm_read_file('test3_math.dat');
   disp(in{1})
   
   fid = cmm_open_read('test3_math.dat');
   dat = cmm_read(fid, 2,1);
   disp(dat)
   cmm_close(fid);
   
   dt = {'hallo' 'dummy' 'dummy' 'world' 'dummy'};
   cmm_write_file('test3_mat.dat', {dt});
   
   dd = cmm_read_file('test3_mat.dat');
   disp(dd{1})
   
   fid = cmm_open_read('test3_mat.dat');
   dat = cmm_read(fid, 1,2);
   disp(dat)
   cmm_close(fid);
   
   
   in = cmm_read_file('test_math_bool.dat')
   
   
   
   % test sequences
   
   in = cmm_read_file('test_math_sequence.dat')
   
   in = cmm_read_file('test_cpp_sequence.dat')
   
   
   f = cmm_open_write('test_mat_sequence.dat');
   
   cmm_write(f, 100);
   
   hs{1,1} = cmm_type(0.1);
   hs{1,2} = [];
   
   hs{2,1} = cmm_type(0.2);
   hs{2,2} = [-1];
   
   cmm_write_header_sequence(f, hs);
   
   
   for i=1:3
      cmm_write_data_sequence(f, i*0.1);
      
      x = [1:i+3];
      cmm_write_data_sequence(f, x);
      
      %this should give error
      %cmm_write_data_sequence(f, 'hallo');
   end
   
   cmm_close(f);
   
   in = cmm_read_file('test_mat_sequence.dat')
   
   
      
   f = cmm_open_write('test_mat_sequence.dat');
   
   hs{1,1} = cmm_type(0.1);
   hs{1,2} = [];
   
   hs{2,1} = cmm_type(0.2);
   hs{2,2} = [5];
   
   cmm_write_header_sequence(f, hs);
   
   for i=1:3
      cmm_write_data_sequence(f, i*0.1);
      
      x = [1:5] + i;
      cmm_write_data_sequence(f, x);
      
   end
   
   cmm_close(f);
    
   in = cmm_read_file('test_mat_sequence.dat')
   
   
   %in = inmath;
   % works  !!!
end