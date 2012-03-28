function type = to_cmm_type(c)
   switch c
      case 'double' 
         type = 'R';
      case 'int32' 
         type = 'I';
      case 'int64'
         type = 'L';
      case 'long'
         type = 'L';
      case 'char'
         type = 'T';
      case 'logical'
         type = 'B';
      otherwise
         error(['Could not find cmm_type for class: ' c]);
         %type = '';
   end
end