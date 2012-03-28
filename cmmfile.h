/***********************************************************************
   cmmfile.h   -  interface in/output for binary data for 
                          use with mathematica (CppBinary.m)
                          and matlab (cppread.m, cppwrite.m)

   usage: cmmfile is fstream and thus works like a stream
      cmmfile << data;
      cmmfile >> data;
      or
      cmmfile.write(dat);
      cmmfile.read(dat);
      useful for writing e.g. vectors V*v
      cmmfile.write(v, size);
      cmmfile.read(v, size);
      note: std:vector<V> v an std::vector< std::vecto<V> > works with << and >>
      ect.

   for more specialized usage there are function templates
      cmmfile.write_type<V>();
      cmmfile.write_size(size...);

      most useful are:
      cmmfile.write_header<V>(size...);
      cmmfile.write_data(dat);

      cmmfile.read_header(type, size);
      cmmfile.read_data(dat);

   the data is stored as follows:
      type(char) dim(uint) size_1(uint) ... size_dim(unit) data

   dim: 0 scalar 
        1 vector
        2 array
        >2 tensor of rank dim

   size: >0 length of corresponding dimension
         -1:first dimension may have size -1:
           -> continuous stream of data -> read/write until end of file

   sequence of types at end of file
      cmmfile.write_start_sequence();
      cmmfile.write_header_sequence<V1>(size...)     // note that size1=-1 is allowed here too !
      cmmfile.write_header_sequence<V2>(size...)
      ...
      cmmfile.write_end_sequence();

      for (i=0; i<n;i++) {
         cmmfile.write_data_sequence<V1>(...)
         cmmfile.write_data_sequence<V2>(...)
         ...
      }

      // reading 
      cmmfile.read_header_sequence();

      // for c++ providing reading of data up to sequence length 4 
      cmmfile.read_sequence(std::vector<V1>, std::vector<V2>)
      cmmfile.read_sequence(std::vector<V1>, std::vector<V2>)
      cmmfile.read_sequence(std::vector<V1>, std::vector<V2>, std::vector<V3>)
      cmmfile.read_sequence(std::vector<V1>, std::vector<V2>, std::vector<V3>, std::vector<V4>)

   Christoph Kirst
   christoph@nld.ds.mpg.de 
   Max Planck Institue for Dynamics and Self-Organisation
************************************************************************/
#ifndef CMMFILE_H
#define CMMFILE_H

#include <iostream>

#include <fstream>
#include <vector>
#include <assert.h>

// datatypes header
#define CMMFile_TYPETYPE char
#define CMMFile_INTG 'I'
#define CMMFile_REAL 'R'
#define CMMFile_TEXT 'T'
#define CMMFile_LONG 'L'
#define CMMFile_ULNG 'U'

#define CMMFile_BOOL 'B'
#define CMMFile_TRUE 't'
#define CMMFile_FALSE 'f' 

#define CMMFile_SEQS 'S'
#define CMMFile_SEQE 'E'

// dimension / size type
#define CMMFile_DIMTYPE int
#define CMMFile_SIZETYPE int

class CMMFile : public std::fstream {
public:
   std::string filename;

   typedef const char * cstr_type;

   struct header {
      CMMFile_TYPETYPE type;
      std::vector<CMMFile_SIZETYPE> dim;
   };

public:
   CMMFile() : filename("") {}
   ~CMMFile() { close(); }

   bool open_write(const std::string & fn)
   {
      filename = fn;
      std::fstream::open(filename.c_str(), std::ios::out | std::ios::binary );
      return std::fstream::good();
   }
   
   bool open_write_append(const std::string & fn)
   {
      filename = fn;
      std::fstream::open(filename.c_str(), std::ios::out | std::ios::binary | std::ios::app);
      return std::fstream::good();
   }
   

   bool open_read(const std::string & fn)
   {
      filename = fn;
      std::fstream::open(filename.c_str(), std::ios::in | std::ios::binary );
      return std::fstream::good();
   }

   void close()
   {
      std::fstream::close();
      filename = "";
   }

public:
/****************************************************************************************
   size of types
*****************************************************************************************/

   int size_of(CMMFile_TYPETYPE type) {
      switch (type) {
         case CMMFile_REAL: return sizeof(double);
         case CMMFile_INTG: return sizeof(int);
         case CMMFile_LONG: return sizeof(long);
         case CMMFile_ULNG: return sizeof(unsigned long);
         case CMMFile_TEXT: return sizeof(char);  // null terminated string -> size of one character  !
         case CMMFile_BOOL: return sizeof(char);
         default:  std::cout << "Unknow Type:" << type << std::endl;
                   assert((type ==CMMFile_REAL) || (type ==CMMFile_INTG) || (type ==CMMFile_LONG) 
                      || (type ==CMMFile_ULNG) || (type ==CMMFile_TEXT) || (type ==CMMFile_BOOL));
      }
   }

   // calculate number of remaining data points for use with -1 dimensons
   template <typename V>
   void tell_size(CMMFile_SIZETYPE& size)
   {
      streampos pos = tellg();
      seekg(0, ios_base::end);
      streampos end = tellg();
      seekg(pos, ios_base::beg);
      size = CMMFile_SIZETYPE((end-pos)/sizeof(V));
   }

   template <typename V>
   void tell_size(CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2) {
      tell_size<V>(size1);
      size1 = CMMFile_SIZETYPE(size1/size2);
   }

   // number of entries gived dimensions d
   inline CMMFile_SIZETYPE length(std::vector<CMMFile_SIZETYPE> d) {
      CMMFile_SIZETYPE n=1;
      for (CMMFile_DIMTYPE i=0; i<d.size(); i++) {
         n*=d[i];
      }
      return n;
   }

public:
/****************************************************************************************
   writing raw data 
*****************************************************************************************/

   template<typename V>
   inline void write_data(const V& v)
   {
      std::fstream::write( (char *) &v, sizeof(V) );
   }

   template<typename V>
   inline void write_data(const std::vector<V>& v)
   {
      std::fstream::write( (char *) &v[0], v.size() * sizeof(V) );
   }


   template<typename V>
   inline void write_data(const std::vector< std::vector<V> >& v) {
      assert(v.size()>0);
      CMMFile_SIZETYPE size = v[0].size();
      for (typename std::vector< std::vector<V> >::const_iterator it = v.begin(); it != v.end(); it++) {
         assert(size == it->size());
      }
      for (typename std::vector< std::vector<V> >::const_iterator it = v.begin(); it != v.end(); it++) {
         std::fstream::write( (char *) &((*it)[0]), size  * sizeof(V) );
      }
   }


   template<typename V, typename S>
   inline void write_data(const V* v, const S& size) {
      std::fstream::write( (char *) v, size * sizeof(V) );
   }

   template<typename V, typename S>
   inline void write_data(const V** v, const S& size1, const S& size2) {
      for (S i = 0; i < size1; i++) {
         std::fstream::write( (char *) &(v[i]), size2  * sizeof(V) );
      }
   }


public:
/****************************************************************************************
   reading raw data 
*****************************************************************************************/


   template<typename V>
   inline void read_data(V& v) {
      std::fstream::read((char *) & v , sizeof(V));
   }

   template<typename V, typename S>
   inline void read_data(std::vector<V>& v, const S& size)
   {
      assert(size >= -1);
      S s = size;
      if (s<0) tell_size<V>(s);
      v.resize(s);
      std::fstream::read((char *) & v[0] , s*sizeof(V));
   }

   template<typename V, typename S>
   inline void read_data(std::vector< std::vector<V> >& v, const S& size1, const S& size2)
   {
      assert(size1 >= -1);
      S s = size1;
      if (s<0) tell_size<V>(s, size2);
      v.resize(s);
      for (typename std::vector< std::vector<V> >::iterator it = v.begin(); it != v.end(); it++)
      {
         it -> resize(size2);
         std::fstream::read( (char *) &((*it)[0]), size2* sizeof(V) );
      }
   }

   template<typename V, typename S>
   inline void read_data(V*& v, const S& size)
   {
      assert(size >= -1);
      S s = size;
      if (s<0) tell_size<V>(s);
      v = new V[s];
      std::fstream::read((char *) & v[0] , s * sizeof(V));
   }

   template<typename V, typename S>
   inline void read_data(V**& v, const S& size1, const S& size2)
   {
      assert(size1 >= -1);
      S s = size1;
      if (s==-1) tell_size<V>(s,size2);
      v = new V*[s];
      for (CMMFile_SIZETYPE i = 1; i< s; i++) {
         v[i] = new V[size2];
         std::fstream::read((char *) v[i] , size2 * sizeof(V));
      }
   }


public:
/****************************************************************************************
   dimensions
*****************************************************************************************/

   //scalar
   inline void write_size(const CMMFile_SIZETYPE& size) {
      std::fstream::write( (char *) &size, sizeof(CMMFile_SIZETYPE));
   }


   inline void write_dim() {
      CMMFile_DIMTYPE dim = 0;
      std::fstream::write( (char *) &dim, sizeof(CMMFile_DIMTYPE));
   }

   //1D vector
   inline void write_dim(const CMMFile_SIZETYPE& size) {
      CMMFile_DIMTYPE dim = 1;
      std::fstream::write( (char *) &dim, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size, sizeof(CMMFile_SIZETYPE));
   }

   //2D array
   inline void write_dim(const CMMFile_DIMTYPE& size1, const CMMFile_DIMTYPE& size2) {
      CMMFile_DIMTYPE dim = 2;
      std::fstream::write( (char *) &dim, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size1, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size2, sizeof(CMMFile_DIMTYPE));
   }
   
   //3D array
   inline void write_dim(const CMMFile_DIMTYPE& size1, const CMMFile_DIMTYPE& size2, const CMMFile_DIMTYPE& size3) {
      CMMFile_DIMTYPE dim = 3;
      std::fstream::write( (char *) &dim, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size1, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size2, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size3, sizeof(CMMFile_DIMTYPE));
   }

   inline void write_dim(std::vector<CMMFile_DIMTYPE> size) {
      CMMFile_DIMTYPE dim = size.size();
      std::fstream::write( (char *) &dim, sizeof(CMMFile_DIMTYPE));
      std::fstream::write( (char *) &size[0], size.size()*sizeof(CMMFile_DIMTYPE));
   }


   inline CMMFile_SIZETYPE read_size() {
      CMMFile_SIZETYPE size;
      std::fstream::read( (char *) &size, sizeof(CMMFile_SIZETYPE));
      //std::cout << "read_size= " << size <<std::endl;
      return size;
   }

   inline CMMFile_DIMTYPE read_dim() {
      CMMFile_DIMTYPE dim;
      std::fstream::read( (char *) &dim, sizeof(CMMFile_DIMTYPE));
      //std::cout << "read_dim=" << dim << std::endl;
      return dim;
   }

   inline void read_dim(std::vector<CMMFile_SIZETYPE>& v) {
      v.resize(read_dim());
      if (v.size()!=0) {
         std::fstream::read((char *) & v[0] , v.size()*sizeof(CMMFile_SIZETYPE));
      }
   }


public:
/****************************************************************************************
   data types
*****************************************************************************************/


   template <typename V>
   CMMFile_TYPETYPE to_type() { assert(false); }

   template <typename V>
   CMMFile_TYPETYPE to_type(CMMFile_TYPETYPE& type) { type = to_type<V>(); }

   template<typename V>
   inline void write_type()  { write_type(to_type<V>()); }

   inline void write_type(const CMMFile_TYPETYPE& type) {
      std::fstream::write(&type, sizeof(CMMFile_TYPETYPE));
   }

   inline CMMFile_TYPETYPE read_type() {
      CMMFile_TYPETYPE t;
      std::fstream::read( (char *) &t, sizeof(CMMFile_TYPETYPE));
      //std::cout << "read_type:" << t <<std::endl;
      return t;
   }

   inline void read_type(CMMFile_TYPETYPE& t) {
      std::fstream::read( (char *) &t, sizeof(CMMFile_TYPETYPE));
   }

   template<typename V>
   bool is_type(const CMMFile_TYPETYPE& type) { return to_type<V>() == type; }


public:
/****************************************************************************************
   headers
*****************************************************************************************/

   template<typename V>
   inline void write_header() {
      write_type<V>();
      write_dim();
   }

   template<typename V>
   inline void write_header(const CMMFile_SIZETYPE& size) {
      write_type<V>();
      write_dim(size);
   }

   template<typename V>
   inline void write_header(const CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2) {
      write_type<V>();
      write_dim(size1, size2);
   }
   
   template<typename V>
   inline void write_header(const CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2, const CMMFile_SIZETYPE& size3) {
      write_type<V>();
      write_dim(size1, size2, size3);
   }

   template<typename V>
   inline void write_header(const std::vector<CMMFile_SIZETYPE>& dim) {
      write_type<V>();
      write_dim(dim);
   }

   inline void write_header(const header& h) {
      write_type(h.type);
      write_dim(h.dim);
   }


   template<typename V>
   inline void read_header() {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 0);
   }

   template<typename V, typename S>
   inline void read_header(S& size) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 1);
      size = read_size();
   }

   template<typename V, typename S>
   inline void read_header(S& size1, S& size2) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 2);
      size1 = read_size();
      size2 = read_size();
   }

   template<typename V, typename S>
   inline void read_header(std::vector<S>& size) {
      assert(is_type<V>(read_type()));
      read_dim(size);
   };

   template<typename S>
   inline void read_header(CMMFile_TYPETYPE& type, std::vector<S>& dim) {
      read_type(type);
      read_dim(dim);
   }

   inline void read_header(header& h) {
      read_type(h.type);
      read_dim(h.dim);
   }


public:
/****************************************************************************************
   writing full data
*****************************************************************************************/

   template<typename V>
   inline void write(const V& v) {
      write_header<V>();
      write_data(v);
   }

   template<typename V>
   inline void write(const std::vector<V>& v) {
      write_header<V>(v.size());
      write_data(v);
   }

   template<typename V>
   inline void write(const std::vector< std::vector<V> >& v) {
      write_header<V>(v.size(), v[0].size());
      write_data(v);
   }

   template<typename V, typename S>
   inline void write(const V* v, const S& size) {
      write_header<V>(size);
      write_data(v, size);
   }

   template<typename V, typename S>
   inline void write(const V** v, const S& size1, const S& size2) {
      write_header<V>(size1, size2);
      write_data(v, size1, size2);
   }


public:
/****************************************************************************************
   reading full data 
*****************************************************************************************/


   template<typename V>
   inline void read(V& v) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 0);
      read_data(v);
   }

   template<typename V>
   inline void read(std::vector<V>& v) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 1);
      read_data(v, read_size());
   }

   template<typename V>
   inline void read(std::vector< std::vector<V> >& v) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 2);
      CMMFile_SIZETYPE size1 = read_size();
      CMMFile_SIZETYPE size2 = read_size();
      read_data(v, size1, size2);
   }

   template<typename V, typename S>
   inline void read(V*& v, S& size) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 1);
      size = read_size();
      read_data(v, size);
   }

   template<typename V, typename S>
   inline void read(V**& v, S& size1, S& size2) {
      assert(is_type<V>(read_type()));
      assert(read_dim() == 2);
      size1 = read_size();
      size2 = read_size();
      read_data(v, size1, size2);
   }



   // operators

   template<typename V>
   CMMFile& operator << (const V& v) {
      write(v);
      return *this;
   }

   template<typename V>
   CMMFile& operator >> (V& v) {
      read(v);
      return *this;
   }



public:
/****************************************************************************************
   sequence of data types 
*****************************************************************************************/


   // sequences of types
   typedef std::vector< header > header_sequence_type;

   header_sequence_type header_sequence;
   header_sequence_type::iterator actual_header;

   void write_start_sequence() {
      header_sequence.clear();
      write_type(CMMFile_SEQS);
   }

   void write_end_sequence()   {
      actual_header = header_sequence.begin();
      write_type(CMMFile_SEQE);
   }

   void increase_actual_header() {
      actual_header++;
      if (actual_header == header_sequence.end()) actual_header =  header_sequence.begin();

      //std::cout << "cmm: " << (*actual_header).type << std::endl;
      //std::cout << "cmm: " << (*actual_header).dim.size() << std::endl;
   }

   template<typename V>
   inline void write_header_sequence() {
      header h;
      h.type = to_type<V>();
      h.dim.clear();
      write_header_sequence(h);
   }

   template<typename V>
   inline void write_header_sequence(const CMMFile_SIZETYPE& size) {
      header h;
      h.type = to_type<V>();
      h.dim.push_back(size);
      write_header_sequence(h);
   }

   template<typename V>
   inline void write_header_sequence(const CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2) {
      header h;
      h.type = to_type<V>();
      h.dim.push_back(size1);
      h.dim.push_back(size2); 
      write_header_sequence(h);
   }

   template<typename V>
   inline void write_header_sequence(const std::vector<CMMFile_SIZETYPE>& dim) {
      header h;
      h.type = to_type<V>();
      for (CMMFile_SIZETYPE i=0; i<dim.size(); i++) {
         h.dim.push_back(dim[i]);
      }
      write_header_sequence(h);
   }

   inline void write_header_sequence(const header& h) {
      write_header(h);
      header_sequence.push_back(h);
   }

   void write_header_sequence(const header_sequence_type& hs) {
      //write_start_sequence();
      for (header_sequence_type::const_iterator it = hs.begin(); it != hs.end(); it++) {
         write_header_sequence(*it);
      }
      //write_end_sequence();
   }


   template<typename V>
   inline void write_data_sequence(const V& v) {
      //check if correct data
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 0);

      write_data<V>(v);
      increase_actual_header();
   }

   template<typename V>
   inline void write_data_sequence(const std::vector<V>& v) {
      //check if correct data
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 1);

      if ((*actual_header).dim[0] == -1) {
         write_size(v.size());
      } else {
         assert((*actual_header).dim[0] == v.size());
      }

      write_data<V>(v);
      increase_actual_header();
   }

   template<typename V>
   inline void write_data_sequence(const std::vector< std::vector<V> >& v) {
      //check if correct data
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 2);

      if ((*actual_header).dim[0] == -1) {
         write_size(v.size());
      } else {
         assert((*actual_header).dim[0] == v.size());
      }
      assert((*actual_header).dim[1] == v[0].size());

      write_data<V>(v);
      increase_actual_header();
   }

   template<typename V, typename S>
   inline void write_data_sequence(const V* v, const S& size) {
      //check if correct data
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 1);

      if ((*actual_header).dim[0] == -1) {
         write_size(size);
      } else {
         assert((*actual_header).dim[0] == size);
      }

      write_data<V>(v, size);
      increase_actual_header();
   }

   template<typename V, typename S>
   inline void write_data_sequence(const V** v, const S& size1, const S& size2) {
      //check if correct data
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 2);

      if ((*actual_header).dim[0] == -1) {
         write_size(size1);
      } else {
         assert((*actual_header).dim[0] == size1);
      }
      assert((*actual_header).dim[1] == v[0].size());

      write_data<V>(v, size1, size2);
      increase_actual_header();
   }

   template<typename V>
   inline void read_data_sequence(V& v) {
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 0);
      read_data(v);
      increase_actual_header();
   }

   template<typename V>
   inline void read_data_sequence(std::vector<V>& v) {
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 1);
      CMMFile_SIZETYPE size = (*actual_header).dim[0];
      if (size ==-1) size = read_size();
      read_data(v, size);
      increase_actual_header();
   }

   template<typename V>
   inline void read_data_sequence(std::vector< std::vector<V> >& v) {
      assert((*actual_header).type == to_type<V>());
      assert((*actual_header).dim.size() == 2);
      CMMFile_SIZETYPE size1 = (*actual_header).dim[0];
      CMMFile_SIZETYPE size2 = (*actual_header).dim[1];
      if (size1 ==-1) size1 = read_size();
      read_data(v, size1, size2);
      increase_actual_header();
   }

   // read a sequence of headers and store in header_sequence
   void read_header_sequence() {
      assert(read_type() == CMMFile_SEQS);
      header_sequence.clear();
      while (peek() != CMMFile_SEQE && !eof())
      {
         //std::cout << "read header sequence peek= " << char(peek()) << " " << eof() << std::endl;
         header h;
         read_header(h);
         header_sequence.push_back(h);
      }
      assert(read_type() == CMMFile_SEQE);
      actual_header = header_sequence.begin();
   }

   template <typename V1, typename V2>
   void read_sequence(std::vector<V1>& v1, std::vector<V2>& v2) {
      read_header_sequence();

      /*
      std::cout << "read sequence" << std::endl;
      for (int i = 0; i< header_sequence.size(); i++) {
         std::cout << header_sequence[i].type << "  " << header_sequence[i].dim.size() << std::endl;
      }*/

      assert(header_sequence.size() == 2);
      v1.clear(); v2.clear();
      V1 e1; V2 e2;

      while (!eof()) {
         read_data_sequence(e1);
         v1.push_back(e1);
         peek();
         assert(!eof());
         read_data_sequence(e2);
         v2.push_back(e2);
         peek();
      }
   }

   template <typename V1, typename V2, typename V3>
   void read_sequence(std::vector<V1>& v1, std::vector<V2>& v2, std::vector<V3>& v3) {
      read_header_sequence();
      assert(header_sequence.size() == 3);
      v1.clear(); v2.clear(); v3.clear();
      V1 e1; V2 e2; V3 e3;
      while (!eof()) {
         read_data_sequence(e1);
         v1.push_back(e1);
         peek();
         assert(!eof());
         read_data_sequence(e2);
         v2.push_back(e2);
         peek();
         assert(!eof());    
         read_data_sequence(e3);
         v3.push_back(e3);
         peek();
      }
   }

   template <typename V1, typename V2, typename V3, typename V4>
   void read_data_sequence(std::vector<V1>& v1, std::vector<V2>& v2, std::vector<V3>& v3, std::vector<V4>& v4) {
      read_header_sequence();
      assert(header_sequence.size() == 4);
      v1.clear(); v2.clear(); v3.clear(); v4.clear();
      V1 e1; V2 e2; V3 e3; V4 e4;
      while (!eof()) {
         read_data_sequence(e1);
         v1.push_back(e1);
         peek();
         assert(!eof());
         read_data_sequence(e2);
         v2.push_back(e2);
         peek();
         assert(!eof());
         read_data_sequence(e3);
         v3.push_back(e3);
         peek();
         assert(!eof());
         read_data_sequence(e4);
         v4.push_back(e4);
         peek();
      }
   }


public:
/****************************************************************************************
   utilities 
*****************************************************************************************/

   //skip a data entry
   void skip() {
      header h;
      read_header(h);
      CMMFile_SIZETYPE l=1;
      assert(h.dim[0] >= 0); // skipping of last entry is nonsense
      skip_data(h.type, length(h.dim));
   }

   //skip n data entries
   void skip(int n) {
      for (int k=0; k<n; k++) skip();
   }

   //skip data entries
   template <typename V>
   void skip_data(CMMFile_SIZETYPE n) {
      seekp(n*sizeof(V), ios_base::cur);
   }
   
   //skip data entries
   template <typename V>
   void skip_data(CMMFile_SIZETYPE s1, CMMFile_SIZETYPE s2) {
      skip_data<V>(s1*s2);
   }

   //skip data entries
   template <typename V>
   void skip_data(std::vector<CMMFile_SIZETYPE> d) {
      skip_data<V>(length(d));
   }

   //template <> void skip_data<std::string>(CMMFile_SIZETYPE n);
   //template <> void skip_data<const char*>(CMMFile_SIZETYPE n);

   void skip_string_data(CMMFile_SIZETYPE n) {
      for(int i=0; i<n; i++) {
         char c;
         std::fstream::read((char *) &c, sizeof(char));
         while ( c != '\0' && ! std::fstream::eof() )
         {
            std::fstream::read((char *) &c, sizeof(char));
         }
      }
   }


   void skip_data(CMMFile_TYPETYPE type, std::vector<CMMFile_SIZETYPE> d) {
      skip_data(type, length(d));
   }

   void skip_data(CMMFile_TYPETYPE type, CMMFile_SIZETYPE n)
   {
      if (type == CMMFile_TEXT)
      {
         skip_string_data(n);
      } else {
         seekp(n*size_of(type), ios_base::cur);
      }
   }

   // skip to last data entry
   void seek_last() {
      CMMFile_TYPETYPE type;
      std::vector<CMMFile_SIZETYPE> d;
      streampos pos;
      CMMFile_SIZETYPE s = 0;

      while (s!=-1 && !eof()) {
         pos = tellp();
         type = read_type();
         read_dim(d);
         if (d.size() > 0) s = d[0]; else s=0;
         if (s!=-1) // skipping this data
         {
            skip_data(type, d);
            peek(); 
            if (eof()) { // we skipped just last entry 
               seekp(pos, ios_base::beg);
               clear();
               s=-1;
            }
         } else { //we are at last entry
            seekp(pos, ios_base::beg);
         }

      }
      assert(!eof());
   }

};





/****************************************************************************************
template specializations 
*****************************************************************************************/


template <>
void CMMFile::tell_size<std::string>(CMMFile_SIZETYPE& size) {
   streampos pos = tellp();
   //search for null terminatons until end of file
   size = 0;
   char c;
   while (!eof()) {
      std::fstream::read(&c, 1);
      if (c == '\0') size++;
   };
   seekp(pos, ios_base::beg);
}

template <>
void CMMFile::tell_size<CMMFile::cstr_type>(CMMFile_SIZETYPE& size) {
   tell_size<std::string>(size);
}


template <>
void CMMFile::tell_size<bool>(CMMFile_SIZETYPE& size) {
   streampos pos = tellg();
   seekg(0, ios_base::end);
   streampos end = tellg();
   seekg(pos, ios_base::beg);
   size = CMMFile_SIZETYPE((end-pos)/sizeof(char));
}




template<>
inline void CMMFile::write_data<CMMFile::cstr_type>(const CMMFile::cstr_type& v) {
   int pos = 0;
   while (v[pos] != '\0') {
      pos++;
   }
   pos++;
   std::fstream::write(v, pos * sizeof(char));
}

template<>
inline void CMMFile::write_data<std::string>(const std::string& v) {
   write_data<CMMFile::cstr_type>(v.c_str());
}

template<>
inline void CMMFile::write_data<bool>(const bool& v)
{
   char c;
   if (v) {
      c = CMMFile_TRUE;
   } else {
      c = CMMFile_FALSE;
   };
   std::fstream::write(&c, sizeof(char));
}



template<>
inline void CMMFile::read_data<std::string>(std::string& v) {
   v = "";
   char c;
   std::fstream::read((char *) &c, sizeof(char));
   while ( c != '\0' && ! std::fstream::eof() )
   {
      v.append(&c, 1);
      std::fstream::read((char *) &c, sizeof(char));
   }
}

template<>
inline void CMMFile::read_data<CMMFile::cstr_type>(CMMFile::cstr_type& v) {
   std::string s;
   read_data<std::string>(s);
   v = s.c_str();
}

template<>
inline void CMMFile::read_data<bool>(bool& v) {
   char c;
   std::fstream::read(&c, sizeof(char));
   if (c == CMMFile_TRUE) {
      v = true;
   } else {
      v = false;
   }
}


template<>
inline void CMMFile::read_data<std::string, CMMFile_SIZETYPE>(std::vector<std::string>& v, const CMMFile_SIZETYPE& size) {
   CMMFile_SIZETYPE s = size;
   if (size<0) {
      v.clear();
      std::string str;
      while (!std::fstream::eof()) {
         read_data<std::string>(str);
         v.push_back(str);
      }
   } else {
      v.resize(size);
      for (std::vector<std::string>::iterator it = v.begin(); it != v.end(); it++)
      {
         read_data<std::string>(*it);
      }
   }
}

template<>
inline void CMMFile::read_data<std::string, CMMFile_SIZETYPE>
(std::vector< std::vector<std::string> >& v, const CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2) {
   CMMFile_SIZETYPE s = size1;
   if (size1<0) {
      v.clear();
      while (!std::fstream::eof()) {
         std::vector<std::string> vs;
         read_data<std::string, CMMFile_SIZETYPE>(vs, size2);
         v.push_back(vs);
      }
   } else {
      v.resize(size1);
      for (std::vector< std::vector<std::string> >::iterator it = v.begin(); it != v.end(); it++)
      {
         read_data< std::string, CMMFile_SIZETYPE >(*it, size2);
      }
   }
}


template<>
inline void CMMFile::read_data<bool, CMMFile_SIZETYPE>(std::vector<bool>& v, const CMMFile_SIZETYPE& size) {
   CMMFile_SIZETYPE s = size;
   if (size<0) { tell_size<bool>(s); }
   v.clear();
   bool b;
   for (CMMFile_SIZETYPE i = 0; i<s; i++) {
      read_data<bool>(b);
      v.push_back(b);
   }
}

template<>
inline void CMMFile::read_data<bool, CMMFile_SIZETYPE>
(std::vector< std::vector<bool> >& v, const CMMFile_SIZETYPE& size1, const CMMFile_SIZETYPE& size2) {
   CMMFile_SIZETYPE s = size1;
   if (size1<0) {
      v.clear();
      while (!std::fstream::eof()) {
         std::vector<bool> vs;
         read_data<bool, CMMFile_SIZETYPE>(vs, size2);
         v.push_back(vs);
      }
   } else {
      v.resize(size1);
      for (std::vector< std::vector<bool> >::iterator it = v.begin(); it != v.end(); it++) {
         read_data<bool, CMMFile_SIZETYPE >(*it, size2);
      }
   }
}



template<>
inline void CMMFile::write_data<std::string>(const std::vector<std::string>& v) {
   for (std::vector<std::string>::const_iterator it = v.begin(); it != v.end(); it++) {
      write_data<std::string>(*it);
   }
}

template<>
inline void CMMFile::write_data<bool>(const std::vector<bool>& v) {
   for (std::vector<bool>::const_iterator it = v.begin(); it != v.end(); it++) {
      write_data<bool>(*it);
   }
}


template<>
inline void CMMFile::write_data<std::string>(const std::vector< std::vector<std::string> >& v) {
   CMMFile_SIZETYPE size = v[0].size();
   for (std::vector< std::vector<std::string> >::const_iterator it = v.begin(); it != v.end(); it++) {
      assert(size == it->size());
   }
   for (std::vector< std::vector<std::string> >::const_iterator it = v.begin(); it != v.end(); it++) {
      write_data<std::string>(*it);
   }
}

template<>
inline void CMMFile::write_data<bool>(const std::vector< std::vector<bool> >& v) {
   assert(v.size()>0);
   CMMFile_SIZETYPE size = v[0].size();
   for (std::vector< std::vector<bool> >::const_iterator it = v.begin(); it != v.end(); it++) {
      assert(size == it->size());
   }
   for (std::vector< std::vector<bool> >::const_iterator it = v.begin(); it != v.end(); it++) {
      write_data<bool>(*it);
   }
}


template <>
void CMMFile::skip_data<std::string>(CMMFile_SIZETYPE n) {
   skip_string_data(n);
}

template <>
void CMMFile::skip_data<const char*>(CMMFile_SIZETYPE n) {
   skip_string_data(n);
}

template <>
void CMMFile::skip_data<bool>(CMMFile_SIZETYPE n) {
   seekp(n*sizeof(char), ios_base::cur);
}



template<>
inline CMMFile_TYPETYPE CMMFile::to_type<double>()        { return CMMFile_REAL; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<int>()           { return CMMFile_INTG; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<long>()          { return CMMFile_LONG; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<unsigned long>() { return CMMFile_ULNG; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<std::string>()   { return CMMFile_TEXT; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<const char*>()   { return CMMFile_TEXT; }
template<>
inline CMMFile_TYPETYPE CMMFile::to_type<bool>()          { return CMMFile_BOOL; }



#endif


