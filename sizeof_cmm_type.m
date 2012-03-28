function b = sizeof_cmm_type(type)
   switch type
      case 'R'
        b = 8;
    case 'I'
        b = 4;
    case 'L'
        b = 8;
    case 'T'
        b = 1;
    case 'B'
        b = 1;
    otherwise
        error(['Could not identify type of data: ' type ]);
   end
end
 