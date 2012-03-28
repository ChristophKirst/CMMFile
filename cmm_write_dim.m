%for scalar size=[]
function cmm_write_dim(fid, size)
   dim = length(size);
   fwrite(fid, dim, 'int32');      %% Write dimension to file
   if (dim>0)
      fwrite(fid,size,'int32');
   end 
end