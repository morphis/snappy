// -*- Mode: Go; indent-tabs-mode: t -*-

/*
 * Copyright (C) 2017 Canonical Ltd
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

package x11

import (
	"encoding/binary"
	"fmt"
	"io"
	"io/ioutil"
	"os"
)

// See https://cgit.freedesktop.org/xorg/lib/libXau/tree/AuRead.c and
// https://cgit.freedesktop.org/xorg/lib/libXau/tree/include/X11/Xauth.h
// for details about the actual file format.
type xauth struct {
	Family  uint16
	Address []byte
	Number  []byte
	Name    []byte
	Data    []byte
}

func readChunk(f *os.File) ([]byte, error) {
	b := [2]byte{}
	n, err := f.Read(b[:])
	if err != nil {
		return nil, err
	} else if n != 2 {
		return nil, fmt.Errorf("Could not read enough bytes")
	}

	size := int(binary.BigEndian.Uint16(b[:]))
	chunk := make([]byte, size)
	n, err = f.Read(chunk)
	if err != nil {
		return nil, err
	} else if n != size {
		return nil, fmt.Errorf("Could not read enough bytes")
	}

	return chunk, nil
}

func (xa *xauth) readFromFile(f *os.File) error {
	b := [2]byte{}
	n, err := f.Read(b[:])
	if err != nil {
		return err
	} else if n != 2 {
		return fmt.Errorf("Could not read enough bytes")
	}
	xa.Family = binary.BigEndian.Uint16(b[:])

	xa.Address, err = readChunk(f)
	if err != nil {
		return err
	}

	xa.Number, err = readChunk(f)
	if err != nil {
		return err
	}

	xa.Name, err = readChunk(f)
	if err != nil {
		return err
	}

	xa.Data, err = readChunk(f)
	if err != nil {
		return err
	}

	return nil
}

// ValidateXauthority validates a given Xauthority file. The file is valid
// if it can be parsed and contains at least one cookie.
func ValidateXauthority(path string) error {
	f, err := os.Open(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return ValidateXauthorityFromFile(f)
}

// ValidateXauthority validates a given Xauthority file. The file is valid
// if it can be parsed and contains at least one cookie.
func ValidateXauthorityFromFile(f *os.File) error {
	cookies := 0
	for {
		xa := &xauth{}
		err := xa.readFromFile(f)
		if err == io.EOF {
			break
		} else if err != nil {
			return err
		}
		cookies++
	}

	if cookies <= 0 {
		return fmt.Errorf("Xauthority file is invalid")
	}

	return nil
}

// MockXauthority will create a fake xauthority file and place it
// on a temporary path which is returned as result.
func MockXauthority(cookies int) (string, error) {
	f, err := ioutil.TempFile("", "xauth")
	if err != nil {
		return "", err
	}
	defer f.Close()
	for n := 0; n < cookies; n++ {
		data := []byte{
			// Family
			0x01, 0x00,
			// Address
			0x00, 0x04, 0x73, 0x6e, 0x61, 0x70,
			// Number
			0x00, 0x01, 0xff,
			// Name
			0x00, 0x05, 0x73, 0x6e, 0x61, 0x70, 0x64,
			// Data
			0x00, 0x01, 0xff,
		}
		m, err := f.Write(data)
		if err != nil {
			return "", err
		} else if m != len(data) {
			return "", fmt.Errorf("Could write cookie")
		}
	}
	return f.Name(), nil
}